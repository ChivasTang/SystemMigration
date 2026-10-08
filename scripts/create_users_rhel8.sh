#!/bin/bash
#=============================================================================
# create_users_rhel8.sh
#   処理用DB老朽化対応（セキュリティ強化）AP サーバ（RHEL 8.10）
#   OS ローカルグループ・ユーザ作成スクリプト（冪等・root で実行）
#
# 使い方:
#   sudo bash create_users_rhel8.sh            # 実行
#   sudo bash create_users_rhel8.sh --dry-run  # 変更を加えずに判定結果だけ表示
#   APP_USER_NAME=tomcat sudo -E bash create_users_rhel8.sh   # weblogic を tomcat に置き換える場合【要確認】
#
# 方針:
#   - set -u（未定義変数をエラー）。set -e は使わず、各処理の結果を [CREATED]/[EXISTS]/[SKIP]/[ERROR] で表示する。
#   - 既存のグループ・ユーザは変更しない（usermod／groupmod／userdel／rm は実行しない）。
#   - UID/GID は参考値が未使用ならそのまま使う。使用済みなら「同じ範囲の次の空き番号」を使い、変更前後を表示する。
#       範囲: 参考値 < 1000 → RHEL 8 のシステム範囲 SYS_UID_MIN(201)～SYS_UID_MAX(999)
#             参考値 >= 1000 → 一般ユーザ範囲 UID_MIN(1000)～UID_MAX(60000)
#       ※ RHEL 8 の推奨（システム用途のユーザも 1000 以上）に合わせて参考値そのものを 1000 以上へ変更するかは【要確認】
#         （cpbackup 501／oinstall 600／weblogic 700 はシステム範囲。既存データの所有者を引き継ぐ観点では参考値のままが有利）。
#   - パスワードは設定しない（useradd 直後はパスワードロック状態。必要なら手順書に従い passwd <ユーザ名> で <パスワード> を設定）。
#   - /bin/ksh を使うユーザがあり ksh が未導入なら dnf install -y ksh を実行する。
#
# 定義（参考値）: 環境定義書「OSユーザ一覧」および依頼の対象ユーザ表
#   グループ: cpbackup 501 / oinstall 600 / pfusr 2200 / ftpuser 2500 / OP 2510
#   ユーザ  : cpbackup 501 / weblogic 700 / cm_usr 2100 / pfusr 2200 / ftpunyo 2500 / opuser 2510
#
# 【要確認】一覧（本スクリプトの前提）
#   1. cpbackup の備考「cpbackup」の意味（GECOS に転記しているが用途は不明）
#   2. weblogic を tomcat に置き換えるか（置き換える場合はユーザ名のみ変更。APP_USER_NAME=tomcat）
#   3. UID/GID を参考値（<1000）のまま使うか、RHEL 8 推奨の 1000 以上に変更するか
#   4. 各ユーザの用途・sudo 権限・補助グループ（例: weblogic の webadmin）・パスワード期限
#   5. ksh ユーザ（cm_usr）の ~/.profile（/etc/skel に無いため作成されない）を用意するか
#   6. パスワード認証の要否（本スクリプトはパスワードを設定しない＝パスワードログイン不可、鍵認証は可）
#=============================================================================
set -u
set -o pipefail
export LC_ALL=C

#---------------------------------------------------------------- オプション
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
    DRY_RUN=1
fi

# weblogic → tomcat 置き換えスイッチ【要確認】（ユーザ名のみ変更。UID/GID/ホーム/シェルの参考値は weblogic と同じ扱い）
APP_USER_NAME="${APP_USER_NAME:-weblogic}"
# 置き換え時のホームディレクトリ（ユーザ名に合わせる。/home/weblogic のまま残す場合は APP_USER_HOME で上書き）
APP_USER_HOME="${APP_USER_HOME:-/home/${APP_USER_NAME}}"

#---------------------------------------------------------------- RHEL 8 の採番範囲（/etc/login.defs の既定値。実機の値で上書き）
SYS_UID_MIN=201;  SYS_UID_MAX=999;  UID_MIN=1000;  UID_MAX=60000
SYS_GID_MIN=201;  SYS_GID_MAX=999;  GID_MIN=1000;  GID_MAX=60000
if [ -r /etc/login.defs ]; then
    for k in SYS_UID_MIN SYS_UID_MAX UID_MIN UID_MAX SYS_GID_MIN SYS_GID_MAX GID_MIN GID_MAX; do
        v=$(awk -v k="$k" '$1==k {print $2}' /etc/login.defs)
        [[ "$v" =~ ^[0-9]+$ ]] && eval "$k=$v"
    done
fi

#---------------------------------------------------------------- グループ定義: 名前:参考GID
# ・oinstall は weblogic(tomcat)／cm_usr の共有プライマリグループ。1 回だけ作成する。
GROUP_DEFS=(
    "cpbackup:501"     # cpbackup ユーザのプライマリグループ。用途は【要確認】（備考「cpbackup」の意味が不明）
    "oinstall:600"     # weblogic(tomcat)・cm_usr の共有プライマリグループ（DB サーバ側の oinstall と同じ GID 600）
    "pfusr:2200"       # pfusr ユーザのプライマリグループ（性能チーム用。環境定義書「ディレクトリ一覧」/disk1/kq/pf）
    "ftpuser:2500"     # ftpunyo ユーザのプライマリグループ（FTP 運用用と思われるが用途は【要確認】）
    "OP:2510"          # opuser ユーザのプライマリグループ（運用用と思われるが用途は【要確認】）
)

#---------------------------------------------------------------- ユーザ定義: 名前:参考UID:プライマリグループ:ホーム:シェル:コメント(GECOS)
# 各ユーザの注釈（用途／権限設定／所属グループ／特殊な設定・制限／UID・GID 変更）は定義の直後に記載。
USER_DEFS=(
    #---- cpbackup -----------------------------------------------------------------
    # 1. 用途      : 共通 PF バックアップ／ミラーリング処理用（環境定義書「ディレクトリ一覧」/disk1/job/comn 配下の所有者）。
    #                備考「cpbackup」の意味は【要確認】（GECOS にそのまま転記）。
    # 2. 権限設定  : sudo なし【要確認】。ホーム /home/cpbackup は useradd -m の既定（login.defs UMASK 077）により 700。
    #                umask は RHEL 8 既定（/etc/bashrc: UID>199 かつ グループ名＝ユーザ名 → 002）【要確認】。
    # 3. 所属      : プライマリ cpbackup（GID 参考値 501）。補助グループなし【要確認】。
    # 4. 特殊設定  : ログインシェル /bin/bash。パスワード未設定（パスワードログイン不可、鍵認証は可）【要確認】。
    #                パスワード期限は login.defs 既定（PASS_MAX_DAYS 99999）【要確認】。
    # 5. UID/GID   : 参考値 501/501（RHEL 8 ではシステム範囲 201～999）。使用済みの場合は実行時に次の空き番号へ変更し、[CHANGED] として表示する。
    "cpbackup:501:cpbackup:/home/cpbackup:/bin/bash:cpbackup"

    #---- weblogic（または tomcat）------------------------------------------------
    # 1. 用途      : WebLogic（移行後は Tomcat 9.0.122）の実行ユーザ。環境定義書「ディレクトリ一覧」/disk1/kq、/disk1/weblogic、/disk1/hyojun 等の所有者。
    #                tomcat へ置き換えるかは【要確認】（置き換える場合は APP_USER_NAME=tomcat。ユーザ名のみ変更し UID 700／oinstall は引き継ぐ）。
    # 2. 権限設定  : sudo なし【要確認】。ホーム 700（環境定義書 /home/weblogic は 700）。umask は RHEL 8 既定（グループ名≠ユーザ名 → 022）。
    #                Tomcat 自体の umask は catalina.sh の UMASK（既定 0027）で別途設定（Tomcat シート）。
    # 3. 所属      : プライマリ oinstall（GID 参考値 600）。補助グループ webadmin（/disk1/hyojun の所有グループ）は定義書に無く【要確認】。
    # 4. 特殊設定  : ログインシェル /bin/bash（/sbin/nologin 化はセキュリティ方針により【要確認】）。パスワード未設定。
    # 5. UID/GID   : 参考値 700/600（システム範囲）。使用済みの場合は実行時に次の空き番号へ変更して表示する。
    "${APP_USER_NAME}:700:oinstall:${APP_USER_HOME}:/bin/bash:"

    #---- cm_usr -------------------------------------------------------------------
    # 1. 用途      : 【要確認】（定義書に記載なし。oinstall グループで /disk1/kq 配下を共有するアプリ関連ユーザと思われる）。
    # 2. 権限設定  : sudo なし【要確認】。ホーム 700（既定）。umask は RHEL 8 既定（oinstall≠cm_usr → 022）【要確認】。
    # 3. 所属      : プライマリ oinstall（GID 参考値 600）。補助グループなし【要確認】。
    # 4. 特殊設定  : ログインシェル /bin/ksh（ksh パッケージ必須。本スクリプトが未導入なら dnf install -y ksh を実行）。
    #                /etc/skel に .profile が無いため ~/.profile は作成されない（ksh 用の環境設定は【要確認】）。パスワード未設定。
    # 5. UID/GID   : 参考値 2100/600。UID 2100 は一般ユーザ範囲。使用済みの場合は次の空き番号へ変更して表示する。
    "cm_usr:2100:oinstall:/home/cm_usr:/bin/ksh:"

    #---- pfusr --------------------------------------------------------------------
    # 1. 用途      : 性能情報取得用（環境定義書「ディレクトリ一覧」/disk1/kq/pf 配下：性能情報取得用 SHELL 格納先、性能チーム作業用）。
    # 2. 権限設定  : sudo なし【要確認】。ホーム 700（既定）。umask は RHEL 8 既定（pfusr＝pfusr → 002）【要確認】。
    # 3. 所属      : プライマリ pfusr（GID 参考値 2200）。補助グループなし【要確認】。
    # 4. 特殊設定  : ログインシェル /bin/bash。パスワード未設定。
    # 5. UID/GID   : 参考値 2200/2200（一般ユーザ範囲）。使用済みの場合は次の空き番号へ変更して表示する。
    "pfusr:2200:pfusr:/home/pfusr:/bin/bash:"

    #---- ftpunyo ------------------------------------------------------------------
    # 1. 用途      : 【要確認】（名称から FTP 運用用と思われるが定義書に記載なし）。
    # 2. 権限設定  : sudo なし【要確認】。ホーム 700（既定）。umask は RHEL 8 既定（ftpuser≠ftpunyo → 022）【要確認】。
    #                vsftpd でホーム配下を公開する場合の chroot・権限は vsftpd シートで扱う【要確認】。
    # 3. 所属      : プライマリ ftpuser（GID 参考値 2500）。補助グループなし【要確認】。
    # 4. 特殊設定  : ログインシェル /bin/bash。パスワード未設定（FTP 認証に OS パスワードを使う場合は設定が必要）【要確認】。
    # 5. UID/GID   : 参考値 2500/2500（一般ユーザ範囲）。使用済みの場合は次の空き番号へ変更して表示する。
    "ftpunyo:2500:ftpuser:/home/ftpunyo:/bin/bash:"

    #---- opuser -------------------------------------------------------------------
    # 1. 用途      : 【要確認】（名称から運用担当用と思われるが定義書に記載なし）。
    # 2. 権限設定  : sudo なし【要確認】（運用用なら sudoers の要否を確認）。ホーム 700（既定）。umask は RHEL 8 既定（OP≠opuser → 022）【要確認】。
    # 3. 所属      : プライマリ OP（GID 参考値 2510）。補助グループなし【要確認】。
    # 4. 特殊設定  : ログインシェル /bin/bash。パスワード未設定。
    # 5. UID/GID   : 参考値 2510/2510（一般ユーザ範囲）。使用済みの場合は次の空き番号へ変更して表示する。
    "opuser:2510:OP:/home/opuser:/bin/bash:"
)

#---------------------------------------------------------------- 共通関数
RC=0
RESULT_ROWS=()          # 結果一覧（ユーザ）
GROUP_ROWS=()           # 結果一覧（グループ）
declare -A GROUP_GID    # グループ名 → 実際の GID

log()     { printf '%s\n' "$*"; }
info()    { log "[INFO]    $*"; }
created() { if [ "$DRY_RUN" -eq 1 ]; then log "[PLAN]    （dry-run）作成予定: $*"; else log "[CREATED] $*"; fi; }
exists()  { log "[EXISTS]  $*"; }
skip()    { log "[SKIP]    $*"; }
changed() { log "[CHANGED] $*"; }
error()   { log "[ERROR]   $*" >&2; RC=1; }

run() {
    # 変更を伴うコマンドの実行（--dry-run のときは表示のみ）
    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY-RUN] $(printf '%q ' "$@")"
        return 0
    fi
    "$@"
}

# 指定範囲で start から上方向に、未使用の GID/UID を探す
find_free_id() {
    local kind=$1 start=$2 lo=$3 hi=$4 n
    n=$start
    [ "$n" -lt "$lo" ] && n=$lo
    while [ "$n" -le "$hi" ]; do
        if [ "$kind" = group ]; then
            getent group "$n" >/dev/null || { echo "$n"; return 0; }
        else
            getent passwd "$n" >/dev/null || { echo "$n"; return 0; }
        fi
        n=$((n + 1))
    done
    return 1
}

# 参考値 ref が属する範囲（lo hi）を返す
id_range() {
    local kind=$1 ref=$2
    if [ "$kind" = group ]; then
        if [ "$ref" -lt "$GID_MIN" ]; then echo "$SYS_GID_MIN $SYS_GID_MAX"; else echo "$GID_MIN $GID_MAX"; fi
    else
        if [ "$ref" -lt "$UID_MIN" ]; then echo "$SYS_UID_MIN $SYS_UID_MAX"; else echo "$UID_MIN $UID_MAX"; fi
    fi
}

#---------------------------------------------------------------- 0. 事前確認
log "=================================================================="
log " ユーザ・グループ作成スクリプト（RHEL 8.10）  $(date '+%Y-%m-%d %H:%M:%S')"
log " ホスト: $(hostname)   DRY_RUN=${DRY_RUN}   APP_USER_NAME=${APP_USER_NAME}"
log "=================================================================="
if [ "$(id -u)" -ne 0 ]; then
    error "root で実行してください（sudo bash $0）"
    exit 1
fi
if [ -r /etc/redhat-release ]; then
    info "OS: $(cat /etc/redhat-release)"
else
    info "OS: /etc/redhat-release なし（RHEL 以外の可能性。採番範囲は login.defs の値を使用）"
fi
info "採番範囲: SYS_UID ${SYS_UID_MIN}-${SYS_UID_MAX} / UID ${UID_MIN}-${UID_MAX} / SYS_GID ${SYS_GID_MIN}-${SYS_GID_MAX} / GID ${GID_MIN}-${GID_MAX}"

#---------------------------------------------------------------- 1. グループ
log ""
log "---- 1. グループの確認・作成 ----"
for def in "${GROUP_DEFS[@]}"; do
    gname=${def%%:*}; gid_ref=${def##*:}
    line=$(getent group "$gname" || true)
    if [ -n "$line" ]; then
        gid_cur=$(echo "$line" | cut -d: -f3)
        GROUP_GID[$gname]=$gid_cur
        if [ "$gid_cur" = "$gid_ref" ]; then
            exists "グループ $gname は既存（GID $gid_cur、参考値と一致）。作成しない。"
            GROUP_ROWS+=("$gname|$gid_cur|既存（参考値どおり）")
        else
            exists "グループ $gname は既存（GID $gid_cur、参考値 $gid_ref と不一致）。変更せず既存 GID を使う。"
            GROUP_ROWS+=("$gname|$gid_cur|既存（参考値 $gid_ref と不一致【要確認】）")
        fi
        continue
    fi
    gid_new=$gid_ref
    note="参考値どおり"
    if getent group "$gid_ref" >/dev/null; then
        read -r lo hi <<<"$(id_range group "$gid_ref")"
        gid_new=$(find_free_id group "$gid_ref" "$lo" "$hi") || { error "グループ $gname: 範囲 ${lo}-${hi} に空き GID がありません"; GROUP_ROWS+=("$gname|-|エラー（空き GID なし）"); continue; }
        changed "グループ $gname: 参考値 GID $gid_ref は $(getent group "$gid_ref" | cut -d: -f1) が使用中 → 同じ範囲（${lo}-${hi}）の次の空き番号 $gid_new を使用"
        note="GID 変更 $gid_ref → $gid_new（参考値が使用済み）"
    fi
    if run groupadd -g "$gid_new" "$gname"; then
        created "グループ $gname（GID $gid_new）"
        GROUP_GID[$gname]=$gid_new
        GROUP_ROWS+=("$gname|$gid_new|作成（$note）")
    else
        error "グループ $gname の作成に失敗（groupadd -g $gid_new $gname）"
        GROUP_ROWS+=("$gname|$gid_new|エラー（groupadd 失敗）")
    fi
done

#---------------------------------------------------------------- 2. ログインシェル（ksh）
log ""
log "---- 2. ログインシェルの確認 ----"
need_ksh=0
for def in "${USER_DEFS[@]}"; do
    IFS=: read -r _ _ _ _ ushell _ <<<"$def"
    [ "$ushell" = /bin/ksh ] && need_ksh=1
done
if [ "$need_ksh" -eq 1 ]; then
    if [ -x /bin/ksh ]; then
        exists "/bin/ksh あり（$(rpm -q ksh 2>/dev/null || echo 'rpm 情報なし')）"
    else
        info "/bin/ksh が無いため ksh パッケージを導入します（dnf install -y ksh）"
        if run dnf install -y ksh; then
            [ "$DRY_RUN" -eq 1 ] || { [ -x /bin/ksh ] && created "ksh 導入（$(rpm -q ksh)）" || error "ksh 導入後も /bin/ksh がありません"; }
        else
            error "ksh の導入に失敗（リポジトリ到達・プロキシを確認）"
        fi
    fi
fi
for sh_ in /bin/bash /bin/ksh; do
    if [ -x "$sh_" ]; then
        # RHEL 7 以降は /bin → /usr/bin のため、/etc/shells は /bin/xxx と /usr/bin/xxx のどちらの登録でも可とする
        if grep -qxE "^(/usr)?${sh_}$" /etc/shells; then info "$sh_ : 存在、/etc/shells 登録あり"; else error "$sh_ : /etc/shells に未登録（chsh や vsftpd のログイン判定で拒否される。ksh パッケージの導入状態を確認）"; fi
    else
        [ "$sh_" = /bin/ksh ] && [ "$need_ksh" -eq 0 ] && continue
        [ "$DRY_RUN" -eq 1 ] && { info "$sh_ : 未導入（dry-run のため導入していない）"; continue; }
        error "$sh_ : 存在しない"
    fi
done

#---------------------------------------------------------------- 3. ユーザ
log ""
log "---- 3. ユーザの確認・作成 ----"
for def in "${USER_DEFS[@]}"; do
    IFS=: read -r uname uid_ref ugroup uhome ushell ucomment <<<"$def"
    if id "$uname" >/dev/null 2>&1; then
        cur=$(getent passwd "$uname")
        IFS=: read -r _ _ uid_cur gid_cur gecos_cur home_cur shell_cur <<<"$cur"
        gname_cur=$(getent group "$gid_cur" | cut -d: -f1)
        exists "ユーザ $uname は既存。作成しない。"
        log "          id     : $(id "$uname")"
        log "          passwd : $cur"
        diff=""
        [ "$uid_cur" = "$uid_ref" ]   || diff+=" UID($uid_cur≠参考値$uid_ref)"
        [ "$gname_cur" = "$ugroup" ]  || diff+=" グループ($gname_cur≠$ugroup)"
        [ "$home_cur" = "$uhome" ]    || diff+=" ホーム($home_cur≠$uhome)"
        [ "$shell_cur" = "$ushell" ]  || diff+=" シェル($shell_cur≠$ushell)"
        if [ -n "$diff" ]; then
            info "定義との差異:$diff → 変更せず【要確認】"
            RESULT_ROWS+=("$uname|$uid_cur|$gid_cur|$gname_cur|$home_cur|$shell_cur|既存（差異:${diff# }【要確認】）")
        else
            RESULT_ROWS+=("$uname|$uid_cur|$gid_cur|$gname_cur|$home_cur|$shell_cur|既存（定義どおり）")
        fi
        continue
    fi
    # プライマリグループの存在確認
    if [ -z "${GROUP_GID[$ugroup]:-}" ]; then
        if [ "$DRY_RUN" -eq 1 ] && getent group "$ugroup" >/dev/null 2>&1; then
            GROUP_GID[$ugroup]=$(getent group "$ugroup" | cut -d: -f3)
        elif [ "$DRY_RUN" -eq 1 ]; then
            GROUP_GID[$ugroup]="(dry-run)"
        else
            error "ユーザ $uname: プライマリグループ $ugroup が存在しないためスキップ"
            RESULT_ROWS+=("$uname|$uid_ref|-|$ugroup|$uhome|$ushell|スキップ（グループ $ugroup なし）")
            continue
        fi
    fi
    gid_use=${GROUP_GID[$ugroup]}
    # UID の重複確認
    uid_new=$uid_ref
    note="参考値どおり"
    if getent passwd "$uid_ref" >/dev/null; then
        read -r lo hi <<<"$(id_range user "$uid_ref")"
        uid_new=$(find_free_id user "$uid_ref" "$lo" "$hi") || { error "ユーザ $uname: 範囲 ${lo}-${hi} に空き UID がありません"; RESULT_ROWS+=("$uname|-|$gid_use|$ugroup|$uhome|$ushell|エラー（空き UID なし）"); continue; }
        changed "ユーザ $uname: 参考値 UID $uid_ref は $(getent passwd "$uid_ref" | cut -d: -f1) が使用中 → 同じ範囲（${lo}-${hi}）の次の空き番号 $uid_new を使用"
        note="UID 変更 $uid_ref → $uid_new（参考値が使用済み）"
    fi
    # シェルの存在確認
    if [ ! -x "$ushell" ] && [ "$DRY_RUN" -eq 0 ]; then
        error "ユーザ $uname: ログインシェル $ushell が存在しないためスキップ"
        RESULT_ROWS+=("$uname|$uid_new|$gid_use|$ugroup|$uhome|$ushell|スキップ（シェル $ushell なし）")
        continue
    fi
    if run useradd -u "$uid_new" -g "$ugroup" -d "$uhome" -m -s "$ushell" -c "$ucomment" "$uname"; then
        created "ユーザ $uname（UID $uid_new、グループ $ugroup（GID $gid_use）、ホーム $uhome、シェル $ushell、コメント \"$ucomment\"）"
        RESULT_ROWS+=("$uname|$uid_new|$gid_use|$ugroup|$uhome|$ushell|作成（$note）")
    else
        error "ユーザ $uname の作成に失敗（useradd -u $uid_new -g $ugroup -d $uhome -m -s $ushell -c \"$ucomment\" $uname）"
        RESULT_ROWS+=("$uname|$uid_new|$gid_use|$ugroup|$uhome|$ushell|エラー（useradd 失敗）")
    fi
done

#---------------------------------------------------------------- 4. 作成後の確認（profile）
log ""
log "---- 4. 作成後の確認（ユーザ切り替え・profile・skel） ----"
if [ "$DRY_RUN" -eq 1 ]; then
    skip "dry-run のため確認を省略"
else
    skel_files=$(cd /etc/skel 2>/dev/null && ls -A1 | tr '\n' ' ')
    info "/etc/skel の配布ファイル: ${skel_files:-（なし）}"
    for def in "${USER_DEFS[@]}"; do
        IFS=: read -r uname _ _ uhome ushell _ <<<"$def"
        id "$uname" >/dev/null 2>&1 || continue
        log ""
        log "  [$uname]"
        if su - "$uname" -c 'id; echo "SHELL=$SHELL"; pwd' 2>&1 | sed 's/^/    /'; then :; else error "$uname: su - に失敗（シェル $ushell を確認）"; fi
        if [ "$ushell" = /bin/ksh ]; then
            if [ -f "$uhome/.profile" ]; then log "    --- ~/.profile ---"; sed 's/^/    | /' "$uhome/.profile"; else info "$uname: ~/.profile なし（/etc/skel に .profile が無いため。ksh 用設定は【要確認】）"; fi
        else
            for f in .bash_profile .bashrc; do
                if [ -f "$uhome/$f" ]; then log "    --- ~/$f ---"; sed 's/^/    | /' "$uhome/$f"; else info "$uname: ~/$f なし"; fi
            done
        fi
        log "    --- ホームの内容（ls -la $uhome） ---"
        ls -la "$uhome" 2>&1 | sed 's/^/    | /'
        for f in $skel_files; do
            [ -e "$uhome/$f" ] || info "$uname: /etc/skel の $f がホームにありません"
        done
    done
fi

#---------------------------------------------------------------- 5. 結果一覧
log ""
log "---- 5. 確認結果の一覧 ----"
printf "%-10s %-6s %s\n" "GROUP" "GID" "STATUS"
for r in "${GROUP_ROWS[@]}"; do IFS='|' read -r a b c <<<"$r"; printf '%-10s %-6s %s\n' "$a" "$b" "$c"; done
log ""
printf "%-10s %-6s %-6s %-10s %-16s %-10s %s\n" "USER" "UID" "GID" "GROUP" "HOME" "SHELL" "STATUS"
for r in "${RESULT_ROWS[@]}"; do IFS='|' read -r a b c d e f g <<<"$r"; printf '%-10s %-6s %-6s %-10s %-16s %-10s %s\n' "$a" "$b" "$c" "$d" "$e" "$f" "$g"; done
log ""
log "getent passwd（作成対象）:"
for def in "${USER_DEFS[@]}"; do IFS=: read -r uname _ <<<"$def"; getent passwd "$uname" || log "  $uname: （未作成）"; done
log ""
if [ "$RC" -eq 0 ]; then
    info "完了（エラーなし）。パスワードは設定していません。必要な場合は passwd <ユーザ名> で <パスワード> を設定してください。"
else
    error "エラーがあります。上記 [ERROR] を確認してください。"
fi
exit "$RC"
