#!/bin/bash
#=============================================================================
# create_dirs_rhel8.sh
#   処理用DB老朽化対応（セキュリティ強化）AP サーバ（RHEL 8.10）
#   ディレクトリ作成スクリプト（冪等・root で実行）
#
# 入力: 環境定義書(icwah01w).xlsx「ディレクトリ一覧」（本番機 icwah01w.ydc.fujixerox.co.jp、RHEL 5.4 の構成）
#       列: ディレクトリパス（階層列 A～Q）／オーナー／グループ／パーミッション／備考（用途）
#       ※ ファイルシステム・容量・マウント有無の列は無い。マウントポイントは /disk1・/disk2 とした【要確認】
#       全 145 行（6～150 行目）を 1 行 1 ディレクトリとして転記。パスは定義書の値をそのまま使用。
#
# 使い方:
#   sudo bash create_dirs_rhel8.sh                      # 実行（所有者 weblogic は定義書どおり）
#   sudo bash create_dirs_rhel8.sh --dry-run            # 変更を加えずに判定結果だけ表示
#   APP_OWNER=tomcat sudo -E bash create_dirs_rhel8.sh  # 所有者 weblogic を tomcat に置き換える場合【要確認】（置き換えた行は [REPLACED] で表示）
#
# 処理（1 ディレクトリごと）:
#   事前確認: 所有者（id）・グループ（getent group）の存在 → 無ければ [SKIP]+[ERROR]
#             マウントポイント配下は findmnt で マウント済みであること → 未マウントなら配下をすべて [SKIP]
#             パスが既に存在する → 作成せず現状（ls -ld）を表示し、定義との差異を [EXISTS] で報告（変更しない）
#   作業    : mkdir -p <パス> → chown <所有者>:<グループ> <パス> → chmod <権限> <パス>（いずれも再帰しない）
#   事後確認: ls -ld <パス>、stat で所有者・グループ・権限が定義どおりか判定
#
# 方針:
#   - set -u。set -e は使わず、結果を [CREATED]/[EXISTS]/[SKIP]/[ERROR]/[OK] で表示し、最後に一覧と件数を表示する。
#   - 既存のディレクトリ・ファイルは削除・上書き・再帰的な chown/chmod をしない（既存は報告のみ）。
#   - 定義書の所有者 weblogic は既定でそのまま使う。tomcat へ置き換えるかは【要確認】（APP_OWNER=tomcat で所有者名のみ置換）。
#   - WebLogic 専用で Tomcat では不要となる可能性のあるパス（/disk1/weblogic 配下、/disk1/job/weblogic 配下、
#     /disk1/job/os/result/weblogic_01・02、/opt/oracle 配下）は推測で削除・変更せず、定義書どおり作成し【要確認】とする。
#   - SELinux が Enforcing／Permissive の場合、作成後に restorecon -Rv <パス>（例: restorecon -Rv /disk1 /disk2）で
#     コンテキストを付与する。本スクリプトでは実行しない（末尾に案内を表示）。httpd が書き込む /disk1/httpd/logs は
#     semanage fcontext -a -t httpd_log_t "/disk1/httpd/logs(/.*)?" の登録が必要【要確認】。
#   - パスワード等の機密情報は含まない。
#
# 所有者 weblogic の行（55 件。APP_OWNER=tomcat 指定時に所有者名を置換する行）:
#   /disk1/kq/pf/seinou(12行目) /disk1/weblogic(13行目) /disk1/weblogic/projects(14行目) /disk1/weblogic/logs(15行目)
#   /disk1/hyojun(16行目) /disk1/hyojun/build_bak(17行目) /disk1/hyojun/build(18行目)
#   /disk1/hyojun/build/webapi(19行目) /disk1/hyojun/build/webapi/application(20行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF(21行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src(22行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp(23行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co(24行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox(25行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq(26行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap(27行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi(28行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean(29行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr/output(31行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl/output(33行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst/output(35行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl/output(37行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl/output(39行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty/output(41行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014/output(43行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015/input(45行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/input(47行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/output(48行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018/input(50行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019/input(52行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020/input(54行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021/input(56行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022/input(58行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023/output(60行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024/input(62行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025/input(64行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026/input(66行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component(67行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic(68行目)
#   /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic/common(69行目)
#   /disk1/hyojun/build/svc_sts(70行目) /disk1/hyojun/build/svc_sts/src(71行目)
#   /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts(76行目)
#   /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/handler(77行目)
#   /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/util(78行目)
#   /disk1/hyojun/build/svc_sts/resource(79行目) /disk1/hyojun/build/svc_sts/lib(80行目)
#   /disk1/hyojun/svc_sts(81行目) /disk1/hyojun/svc_sts/lib(82行目) /disk1/hyojun/svc_sts/logs(83行目)
#   /opt/oracle(134行目) /opt/oracle/middleware(135行目) /opt/oracle/middleware/wlserver_10.3(136行目)
#   /home/weblogic(138行目) /home/weblogic/add_on(139行目)
#
# 【要確認】一覧: スクリプト末尾を参照
#=============================================================================
set -u
set -o pipefail
export LC_ALL=C

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then DRY_RUN=1; fi

# 所有者 weblogic の置き換え先【要確認】（既定: weblogic のまま。tomcat に置き換える場合は APP_OWNER=tomcat）
APP_OWNER="${APP_OWNER:-weblogic}"

# マウントポイント（配下を作成する前に findmnt でマウント済みであることを確認する）【要確認】定義書にマウント有無の列は無い
MOUNTPOINTS=(/disk1 /disk2)

#---------------------------------------------------------------- ディレクトリ定義
# 形式: "パス|所有者|グループ|権限|用途（定義書の備考）"
# 各行のコメント: 定義書の行番号／用途／所有者:グループ／権限／注意点。用途が定義書に無いものは【要確認】。
DIRS=(
    # [6行目] /disk1 | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: マウントポイント（ディスク構成手順でマウント済みであること。findmnt で確認）
    "/disk1|root|root|755|"
    # [7行目] /disk1/kq | 用途: （定義書に記載なし）【要確認】 | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/kq|root|root|777|"
    # [8行目] /disk1/kq/pf | 用途: （定義書に記載なし）【要確認】 | pfusr:pfusr 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/kq/pf|pfusr|pfusr|777|"
    # [9行目] /disk1/kq/pf/pfusr | 用途: （定義書に記載なし）【要確認】 | pfusr:pfusr 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/kq/pf/pfusr|pfusr|pfusr|777|"
    # [10行目] /disk1/kq/pf/pfusr/seinou | 用途: 性能情報取得用SHELL格納先、性能情報格納先 | pfusr:pfusr 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/kq/pf/pfusr/seinou|pfusr|pfusr|777|性能情報取得用SHELL格納先、性能情報格納先"
    # [11行目] /disk1/kq/pf/pfusr/work | 用途: 性能チーム作業用ディレクトリ | pfusr:pfusr 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/kq/pf/pfusr/work|pfusr|pfusr|777|性能チーム作業用ディレクトリ"
    # [12行目] /disk1/kq/pf/seinou | 用途: 性能情報取得用SHELL格納先、性能情報格納先 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）；グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/kq/pf/seinou|weblogic|webadmin|777|性能情報取得用SHELL格納先、性能情報格納先"
    # [13行目] /disk1/weblogic | 用途: Weblogicディレクトリ (※[統合顧客DBシステム WebLogic設計書]を参照) | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/disk1/weblogic|weblogic|oinstall|755|Weblogicディレクトリ (※[統合顧客DBシステム WebLogic設計書]を参照)"
    # [14行目] /disk1/weblogic/projects | 用途: （定義書に記載なし）【要確認】 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/disk1/weblogic/projects|weblogic|oinstall|755|"
    # [15行目] /disk1/weblogic/logs | 用途: （定義書に記載なし）【要確認】 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/weblogic/logs|weblogic|oinstall|777|"
    # [16行目] /disk1/hyojun | 用途: マスタメンテナンス機能リリース | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun|weblogic|webadmin|775|マスタメンテナンス機能リリース"
    # [17行目] /disk1/hyojun/build_bak | 用途: Warファイルの退避ディレクトリ | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build_bak|weblogic|webadmin|775|Warファイルの退避ディレクトリ"
    # [18行目] /disk1/hyojun/build | 用途: マスタメンテナンス機能リリース | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build|weblogic|webadmin|775|マスタメンテナンス機能リリース"
    # [19行目] /disk1/hyojun/build/webapi | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi|weblogic|webadmin|775|"
    # [20行目] /disk1/hyojun/build/webapi/application | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application|weblogic|webadmin|775|"
    # [21行目] /disk1/hyojun/build/webapi/application/WEB-INF | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF|weblogic|webadmin|775|"
    # [22行目] /disk1/hyojun/build/webapi/application/WEB-INF/src | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src|weblogic|webadmin|775|"
    # [23行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp|weblogic|webadmin|775|"
    # [24行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co|weblogic|webadmin|775|"
    # [25行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox|weblogic|webadmin|775|"
    # [26行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq|weblogic|webadmin|775|"
    # [27行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap|weblogic|webadmin|775|"
    # [28行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi|weblogic|webadmin|775|"
    # [29行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean|weblogic|webadmin|775|"
    # [30行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr|root|root|775|"
    # [31行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr/output|weblogic|webadmin|775|"
    # [32行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl|root|root|775|"
    # [33行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl/output|weblogic|webadmin|775|"
    # [34行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst|root|root|775|"
    # [35行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst/output|weblogic|webadmin|775|"
    # [36行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl|root|root|775|"
    # [37行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl/output|weblogic|webadmin|775|"
    # [38行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl|root|root|775|"
    # [39行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl/output|weblogic|webadmin|775|"
    # [40行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty|root|root|775|"
    # [41行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty/output|weblogic|webadmin|775|"
    # [42行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014|root|root|775|"
    # [43行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014/output|weblogic|webadmin|775|"
    # [44行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015|root|root|775|"
    # [45行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015/input|weblogic|webadmin|775|"
    # [46行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017|root|root|775|"
    # [47行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/input|weblogic|webadmin|775|"
    # [48行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/output|weblogic|webadmin|775|"
    # [49行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018|root|root|775|"
    # [50行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018/input|weblogic|webadmin|775|"
    # [51行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019|root|root|775|"
    # [52行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019/input|weblogic|webadmin|775|"
    # [53行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020|root|root|775|"
    # [54行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020/input|weblogic|webadmin|775|"
    # [55行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021|root|root|775|"
    # [56行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021/input|weblogic|webadmin|775|"
    # [57行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022|root|root|775|"
    # [58行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022/input|weblogic|webadmin|775|"
    # [59行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023|root|root|775|"
    # [60行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023/output | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023/output|weblogic|webadmin|775|"
    # [61行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024|root|root|775|"
    # [62行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024/input|weblogic|webadmin|775|"
    # [63行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025|root|root|775|"
    # [64行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025/input|weblogic|webadmin|775|"
    # [65行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026 | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026|root|root|775|"
    # [66行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026/input | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026/input|weblogic|webadmin|775|"
    # [67行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component|weblogic|webadmin|775|"
    # [68行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic|weblogic|webadmin|775|"
    # [69行目] /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic/common | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic/common|weblogic|webadmin|775|"
    # [70行目] /disk1/hyojun/build/svc_sts | 用途: サービスステータス監視機能リリース | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts|weblogic|webadmin|775|サービスステータス監視機能リリース"
    # [71行目] /disk1/hyojun/build/svc_sts/src | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts/src|weblogic|webadmin|775|"
    # [72行目] /disk1/hyojun/build/svc_sts/src/jp | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/svc_sts/src/jp|root|root|775|"
    # [73行目] /disk1/hyojun/build/svc_sts/src/jp/co | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/svc_sts/src/jp/co|root|root|775|"
    # [74行目] /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/svc_sts/src/jp/co/fujixerox|root|root|775|"
    # [75行目] /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq | 用途: （定義書に記載なし）【要確認】 | root:root 775
    "/disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq|root|root|775|"
    # [76行目] /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts|weblogic|webadmin|775|"
    # [77行目] /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/handler | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/handler|weblogic|webadmin|775|"
    # [78行目] /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/util | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/util|weblogic|webadmin|775|"
    # [79行目] /disk1/hyojun/build/svc_sts/resource | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts/resource|weblogic|webadmin|775|"
    # [80行目] /disk1/hyojun/build/svc_sts/lib | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/build/svc_sts/lib|weblogic|webadmin|775|"
    # [81行目] /disk1/hyojun/svc_sts | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/svc_sts|weblogic|webadmin|775|"
    # [82行目] /disk1/hyojun/svc_sts/lib | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/svc_sts/lib|weblogic|webadmin|775|"
    # [83行目] /disk1/hyojun/svc_sts/logs | 用途: （定義書に記載なし）【要確認】 | weblogic:webadmin（weblogic → ${APP_OWNER} に置換可【要確認】） 775 | 注意: グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】
    "/disk1/hyojun/svc_sts/logs|weblogic|webadmin|775|"
    # [84行目] /disk1/httpd | 用途: （定義書に記載なし）【要確認】 | root:root 755
    "/disk1/httpd|root|root|755|"
    # [85行目] /disk1/httpd/logs | 用途: Apacheアクセス・エラーログ格納ディレクトリ | root:root 700
    "/disk1/httpd/logs|root|root|700|Apacheアクセス・エラーログ格納ディレクトリ"
    # [86行目] /disk1/job | 用途: （定義書に記載なし）【要確認】 | root:root 755
    "/disk1/job|root|root|755|"
    # [87行目] /disk1/job/conf | 用途: パラメータファイル格納ディレクトリ | root:root 755
    "/disk1/job/conf|root|root|755|パラメータファイル格納ディレクトリ"
    # [88行目] /disk1/job/os | 用途: os用プログラム格納ディレクトリ | root:root 755
    "/disk1/job/os|root|root|755|os用プログラム格納ディレクトリ"
    # [89行目] /disk1/job/os/file_purge | 用途: ファイルパージ処理用ディレクトリ | root:root 755
    "/disk1/job/os/file_purge|root|root|755|ファイルパージ処理用ディレクトリ"
    # [90行目] /disk1/job/os/file_purge/scripts | 用途: メインプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/scripts|root|root|777|メインプログラム格納ディレクトリ"
    # [91行目] /disk1/job/os/file_purge/sub | 用途: サブプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/sub|root|root|777|サブプログラム格納ディレクトリ"
    # [92行目] /disk1/job/os/file_purge/sql | 用途: SQLプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/sql|root|root|777|SQLプログラム格納ディレクトリ"
    # [93行目] /disk1/job/os/file_purge/out | 用途: アウトプットファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/out|root|root|777|アウトプットファイル格納ディレクトリ"
    # [94行目] /disk1/job/os/file_purge/tmp | 用途: 一時ファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/tmp|root|root|777|一時ファイル格納ディレクトリ"
    # [95行目] /disk1/job/os/file_purge/result | 用途: 結果ファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/result|root|root|777|結果ファイル格納ディレクトリ"
    # [96行目] /disk1/job/os/file_purge/log | 用途: ログファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/file_purge/log|root|root|777|ログファイル格納ディレクトリ"
    # [97行目] /disk1/job/os/scripts | 用途: (監査ログ取得処理用)メインプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/scripts|root|root|777|(監査ログ取得処理用)メインプログラム格納ディレクトリ"
    # [98行目] /disk1/job/os/result | 用途: (監査ログ取得処理用)サブプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/result|root|root|777|(監査ログ取得処理用)サブプログラム格納ディレクトリ"
    # [99行目] /disk1/job/os/result/apache | 用途: apache監査ログ格納ディレクトリ | root:root 755
    "/disk1/job/os/result/apache|root|root|755|apache監査ログ格納ディレクトリ"
    # [100行目] /disk1/job/os/result/ftp | 用途: ftp監査ログ格納ディレクトリ | root:root 755
    "/disk1/job/os/result/ftp|root|root|755|ftp監査ログ格納ディレクトリ"
    # [101行目] /disk1/job/os/result/iptables | 用途: iptables監査ログ格納ディレクトリ | root:root 755
    "/disk1/job/os/result/iptables|root|root|755|iptables監査ログ格納ディレクトリ"
    # [102行目] /disk1/job/os/result/oracle | 用途: oracle監査ログ格納ディレクトリ | root:root 755
    "/disk1/job/os/result/oracle|root|root|755|oracle監査ログ格納ディレクトリ"
    # [103行目] /disk1/job/os/result/ssh | 用途: ssh監査ログ格納ディレクトリ | root:root 755
    "/disk1/job/os/result/ssh|root|root|755|ssh監査ログ格納ディレクトリ"
    # [104行目] /disk1/job/os/result/weblogic_01 | 用途: weblogic_01監査ログ格納ディレクトリ | root:root 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/disk1/job/os/result/weblogic_01|root|root|755|weblogic_01監査ログ格納ディレクトリ"
    # [105行目] /disk1/job/os/result/weblogic_02 | 用途: weblogic_02監査ログ格納ディレクトリ | root:root 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/disk1/job/os/result/weblogic_02|root|root|755|weblogic_02監査ログ格納ディレクトリ"
    # [106行目] /disk1/job/os/tmp | 用途: (監査ログ取得処理用)一時ファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/tmp|root|root|777|(監査ログ取得処理用)一時ファイル格納ディレクトリ"
    # [107行目] /disk1/job/os/conf | 用途: (監査ログ取得処理用)対象ファイルリスト格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/conf|root|root|777|(監査ログ取得処理用)対象ファイルリスト格納ディレクトリ"
    # [108行目] /disk1/job/os/log | 用途: (監査ログ取得処理用)ログファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/os/log|root|root|777|(監査ログ取得処理用)ログファイル格納ディレクトリ"
    # [109行目] /disk1/job/comn | 用途: 共通PFバックアッププログラム格納ディレクトリ | cpbackup:cpbackup 755
    "/disk1/job/comn|cpbackup|cpbackup|755|共通PFバックアッププログラム格納ディレクトリ"
    # [110行目] /disk1/job/comn/backup | 用途: 共通PFバックアップ/ミラーリング処理用ディレクトリ | cpbackup:cpbackup 755
    "/disk1/job/comn/backup|cpbackup|cpbackup|755|共通PFバックアップ/ミラーリング処理用ディレクトリ"
    # [111行目] /disk1/job/comn/backup/scripts | 用途: メインプログラム格納ディレクトリ | cpbackup:cpbackup 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/comn/backup/scripts|cpbackup|cpbackup|777|メインプログラム格納ディレクトリ"
    # [112行目] /disk1/job/comn/backup/sub | 用途: サブプログラム格納ディレクトリ | cpbackup:cpbackup 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/comn/backup/sub|cpbackup|cpbackup|777|サブプログラム格納ディレクトリ"
    # [113行目] /disk1/job/comn/backup/sql | 用途: SQLプログラム格納ディレクトリ | cpbackup:cpbackup 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/comn/backup/sql|cpbackup|cpbackup|777|SQLプログラム格納ディレクトリ"
    # [114行目] /disk1/job/comn/backup/out | 用途: アウトプットファイル格納ディレクトリ | cpbackup:cpbackup 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/comn/backup/out|cpbackup|cpbackup|777|アウトプットファイル格納ディレクトリ"
    # [115行目] /disk1/job/comn/backup/tmp | 用途: 一時ファイル格納ディレクトリ | cpbackup:cpbackup 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/comn/backup/tmp|cpbackup|cpbackup|777|一時ファイル格納ディレクトリ"
    # [116行目] /disk1/job/comn/backup/log | 用途: ログファイル格納ディレクトリ | cpbackup:cpbackup 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/comn/backup/log|cpbackup|cpbackup|777|ログファイル格納ディレクトリ"
    # [117行目] /disk1/job/weblogic | 用途: Weblogic起動・停止処理用ディレクトリ | root:root 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/disk1/job/weblogic|root|root|755|Weblogic起動・停止処理用ディレクトリ"
    # [118行目] /disk1/job/weblogic/scripts | 用途: メインプログラム格納ディレクトリ | root:root 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/weblogic/scripts|root|root|777|メインプログラム格納ディレクトリ"
    # [119行目] /disk1/job/weblogic/sub | 用途: サブプログラム格納ディレクトリ | root:root 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/weblogic/sub|root|root|777|サブプログラム格納ディレクトリ"
    # [120行目] /disk1/job/weblogic/sql | 用途: SQLプログラム格納ディレクトリ | root:root 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/weblogic/sql|root|root|777|SQLプログラム格納ディレクトリ"
    # [121行目] /disk1/job/weblogic/out | 用途: アウトプットファイル格納ディレクトリ | root:root 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/weblogic/out|root|root|777|アウトプットファイル格納ディレクトリ"
    # [122行目] /disk1/job/weblogic/tmp | 用途: 一時ファイル格納ディレクトリ | root:root 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/weblogic/tmp|root|root|777|一時ファイル格納ディレクトリ"
    # [123行目] /disk1/job/weblogic/log | 用途: ログファイル格納ディレクトリ | root:root 777 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/weblogic/log|root|root|777|ログファイル格納ディレクトリ"
    # [124行目] /disk1/job/apache | 用途: Apache起動・停止処理用ディレクトリ | root:root 755
    "/disk1/job/apache|root|root|755|Apache起動・停止処理用ディレクトリ"
    # [125行目] /disk1/job/apache/scripts | 用途: メインプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/apache/scripts|root|root|777|メインプログラム格納ディレクトリ"
    # [126行目] /disk1/job/apache/sub | 用途: サブプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/apache/sub|root|root|777|サブプログラム格納ディレクトリ"
    # [127行目] /disk1/job/apache/sql | 用途: SQLプログラム格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/apache/sql|root|root|777|SQLプログラム格納ディレクトリ"
    # [128行目] /disk1/job/apache/out | 用途: アウトプットファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/apache/out|root|root|777|アウトプットファイル格納ディレクトリ"
    # [129行目] /disk1/job/apache/tmp | 用途: 一時ファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/apache/tmp|root|root|777|一時ファイル格納ディレクトリ"
    # [130行目] /disk1/job/apache/log | 用途: ログファイル格納ディレクトリ | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk1/job/apache/log|root|root|777|ログファイル格納ディレクトリ"
    # [131行目] /disk2 | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: マウントポイント（ディスク構成手順でマウント済みであること。findmnt で確認）
    "/disk2|root|root|755|"
    # [132行目] /disk2/purge | 用途: ファイルパージ処理退避圧縮ファイル格納ディレクトリ (※[統合顧客DB-機能設計書(ファイルパージ処理)]を参照) | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/disk2/purge|root|root|777|ファイルパージ処理退避圧縮ファイル格納ディレクトリ (※[統合顧客DB-機能設計書(ファイルパージ処理)]を参照)"
    # [133行目] /opt | 用途: Weblogicインストールディレクトリ (※[統合顧客DBシステム WebLogic設計書]を参照) | root:root 755 | 注意: OS 標準で存在（既存として報告される）
    "/opt|root|root|755|Weblogicインストールディレクトリ (※[統合顧客DBシステム WebLogic設計書]を参照)"
    # [134行目] /opt/oracle | 用途: （定義書に記載なし）【要確認】 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/opt/oracle|weblogic|oinstall|755|"
    # [135行目] /opt/oracle/middleware | 用途: （定義書に記載なし）【要確認】 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 750 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/opt/oracle/middleware|weblogic|oinstall|750|"
    # [136行目] /opt/oracle/middleware/wlserver_10.3 | 用途: （定義書に記載なし）【要確認】 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）
    "/opt/oracle/middleware/wlserver_10.3|weblogic|oinstall|755|"
    # [137行目] /home | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示）
    "/home|root|root|755|"
    # [138行目] /home/weblogic | 用途: （定義書に記載なし）【要確認】 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 700 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；ホームは useradd -m（ユーザ・グループ手順）で作成済みのはず。未作成なら本スクリプトが作成する
    "/home/weblogic|weblogic|oinstall|700|"
    # [139行目] /home/weblogic/add_on | 用途: リリース作業用 | weblogic:oinstall（weblogic → ${APP_OWNER} に置換可【要確認】） 755 | 注意: WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；ホームは useradd -m（ユーザ・グループ手順）で作成済みのはず。未作成なら本スクリプトが作成する
    "/home/weblogic/add_on|weblogic|oinstall|755|リリース作業用"
    # [140行目] /work | 用途: （定義書に記載なし）【要確認】 | root:root 755
    "/work|root|root|755|"
    # [141行目] /work/OS | 用途: （定義書に記載なし）【要確認】 | root:root 777 | 注意: 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/work/OS|root|root|777|"
    # [142行目] /work/OS/iptables | 用途: iptables設定作業用ディレクトリ | root:root 777 | 注意: RHEL 8 は firewalld のため用途の継続要否【要確認】；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）
    "/work/OS/iptables|root|root|777|iptables設定作業用ディレクトリ"
    # [143行目] /usr | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示）
    "/usr|root|root|755|"
    # [144行目] /usr/local | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示）
    "/usr/local|root|root|755|"
    # [145行目] /usr/local/bin | 用途: aws cliコマンド(symlink)格納ディレクトリ | root:root 755 | 注意: OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示）
    "/usr/local/bin|root|root|755|aws cliコマンド(symlink)格納ディレクトリ"
    # [146行目] /usr/local/lib | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示）
    "/usr/local/lib|root|root|755|"
    # [147行目] /usr/local/lib/aws | 用途: aws cliパッケージインストール先 | root:root 755 | 注意: AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】
    "/usr/local/lib/aws|root|root|755|aws cliパッケージインストール先"
    # [148行目] /usr/local/lib/aws/bin | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】
    "/usr/local/lib/aws/bin|root|root|755|"
    # [149行目] /usr/local/lib/aws/include | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】
    "/usr/local/lib/aws/include|root|root|755|"
    # [150行目] /usr/local/lib/aws/lib | 用途: （定義書に記載なし）【要確認】 | root:root 755 | 注意: AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】
    "/usr/local/lib/aws/lib|root|root|755|"
)

#---------------------------------------------------------------- 共通
RC=0
N_CREATED=0; N_EXISTS=0; N_SKIP=0; N_ERROR=0; N_DIFF=0
RESULTS=()
REPLACED=()
declare -A UNMOUNTED

log()     { printf '%s\n' "$*"; }
info()    { log "[INFO]    $*"; }
created() { if [ "$DRY_RUN" -eq 1 ]; then log "[PLAN]    （dry-run）作成予定: $*"; else log "[CREATED] $*"; fi; }
exists()  { log "[EXISTS]  $*"; }
skip()    { log "[SKIP]    $*"; }
ok()      { log "[OK]      $*"; }
error()   { log "[ERROR]   $*" >&2; RC=1; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then log "[DRY-RUN] $(printf '%q ' "$@")"; return 0; fi
    "$@"
}

#---------------------------------------------------------------- 0. 事前確認（全体）
log "=================================================================="
log " ディレクトリ作成スクリプト（RHEL 8.10）  $(date '+%Y-%m-%d %H:%M:%S')"
log " ホスト: $(hostname)   DRY_RUN=${DRY_RUN}   APP_OWNER=${APP_OWNER}   対象: ${#DIRS[@]} 件"
log "=================================================================="
if [ "$(id -u)" -ne 0 ]; then error "root で実行してください（sudo bash $0）"; exit 1; fi
[ -r /etc/redhat-release ] && info "OS: $(cat /etc/redhat-release)"
if command -v getenforce >/dev/null 2>&1; then info "SELinux: $(getenforce)"; else info "SELinux: getenforce なし"; fi

log ""
log "---- 0-1. 所有者・グループの存在確認 ----"
for u in $(printf '%s\n' "${DIRS[@]}" | cut -d'|' -f2 | sort -u); do
    uu=$u; [ "$u" = weblogic ] && uu=$APP_OWNER
    if id "$uu" >/dev/null 2>&1; then info "ユーザ $uu : あり（$(id "$uu")）"; else error "ユーザ $uu : なし（このユーザが所有者の行はスキップする）"; fi
done
for g in $(printf '%s\n' "${DIRS[@]}" | cut -d'|' -f3 | sort -u); do
    if getent group "$g" >/dev/null; then info "グループ $g : あり（$(getent group "$g")）"; else error "グループ $g : なし（このグループの行はスキップする）"; fi
done

log ""
log "---- 0-2. マウントポイントの確認 ----"
for mp in "${MOUNTPOINTS[@]}"; do
    if findmnt -n "$mp" >/dev/null 2>&1; then
        info "$mp : マウント済み（$(findmnt -n -o SOURCE,FSTYPE,OPTIONS "$mp")）"
    else
        error "$mp : 未マウント（配下のディレクトリはすべてスキップする。ディスク構成手順を先に実施）"
        UNMOUNTED[$mp]=1
    fi
done

#---------------------------------------------------------------- 1. ディレクトリごとの処理
log ""
log "---- 1. ディレクトリの作成（mkdir -p → chown → chmod → ls -ld） ----"
for def in "${DIRS[@]}"; do
    IFS='|' read -r path owner group mode purpose <<<"$def"
    if [ "$owner" = weblogic ] && [ "$APP_OWNER" != weblogic ]; then
        owner=$APP_OWNER
        REPLACED+=("$path")
        log "[REPLACED] $path : 所有者 weblogic → $owner（APP_OWNER 指定）"
    fi
    # マウント未済の配下はスキップ
    for mp in "${!UNMOUNTED[@]}"; do
        case "$path" in
            "$mp"|"$mp"/*)
                skip "$path : $mp が未マウントのためスキップ"
                RESULTS+=("$path|$owner|$group|$mode|スキップ（$mp 未マウント）"); N_SKIP=$((N_SKIP+1))
                continue 2 ;;
        esac
    done
    # 所有者・グループの存在
    if ! id "$owner" >/dev/null 2>&1; then
        error "$path : 所有者 $owner が存在しないためスキップ"
        RESULTS+=("$path|$owner|$group|$mode|スキップ（所有者 $owner なし）"); N_SKIP=$((N_SKIP+1)); continue
    fi
    if ! getent group "$group" >/dev/null; then
        error "$path : グループ $group が存在しないためスキップ"
        RESULTS+=("$path|$owner|$group|$mode|スキップ（グループ $group なし）"); N_SKIP=$((N_SKIP+1)); continue
    fi
    # 既存確認（存在する場合は変更しない）
    if [ -e "$path" ]; then
        if [ ! -d "$path" ]; then
            error "$path : ディレクトリ以外のファイルが存在する（$(ls -ld "$path")）"
            RESULTS+=("$path|$owner|$group|$mode|エラー（ディレクトリ以外が存在）"); N_ERROR=$((N_ERROR+1)); continue
        fi
        cur_owner=$(stat -c '%U' "$path"); cur_group=$(stat -c '%G' "$path"); cur_mode=$(stat -c '%a' "$path")
        diff=""
        [ "$cur_owner" = "$owner" ] || diff+=" 所有者($cur_owner≠$owner)"
        [ "$cur_group" = "$group" ] || diff+=" グループ($cur_group≠$group)"
        [ "$cur_mode"  = "$mode"  ] || diff+=" 権限($cur_mode≠$mode)"
        if [ -n "$diff" ]; then
            exists "$path : 既存（定義と差異あり:${diff}）→ 変更しない【要確認】  $(ls -ld "$path")"
            RESULTS+=("$path|$cur_owner|$cur_group|$cur_mode|既存（差異:${diff# }【要確認】）"); N_DIFF=$((N_DIFF+1))
        else
            exists "$path : 既存（定義どおり）  $(ls -ld "$path")"
            RESULTS+=("$path|$cur_owner|$cur_group|$cur_mode|既存（定義どおり）")
        fi
        N_EXISTS=$((N_EXISTS+1)); continue
    fi
    # 作成
    if ! run mkdir -p "$path"; then
        error "$path : mkdir に失敗"; RESULTS+=("$path|$owner|$group|$mode|エラー（mkdir 失敗）"); N_ERROR=$((N_ERROR+1)); continue
    fi
    if ! run chown "$owner:$group" "$path"; then
        error "$path : chown に失敗"; RESULTS+=("$path|$owner|$group|$mode|エラー（chown 失敗）"); N_ERROR=$((N_ERROR+1)); continue
    fi
    if ! run chmod "$mode" "$path"; then
        error "$path : chmod に失敗"; RESULTS+=("$path|$owner|$group|$mode|エラー（chmod 失敗）"); N_ERROR=$((N_ERROR+1)); continue
    fi
    created "$path（$owner:$group $mode）"
    N_CREATED=$((N_CREATED+1))
    # 事後確認
    if [ "$DRY_RUN" -eq 1 ]; then
        RESULTS+=("$path|$owner|$group|$mode|作成予定（dry-run）"); continue
    fi
    cur=$(stat -c '%U:%G %a' "$path")
    if [ "$cur" = "$owner:$group $mode" ]; then
        ok "$(ls -ld "$path")"
        RESULTS+=("$path|$owner|$group|$mode|作成（確認 OK）")
    else
        error "$path : 作成後の確認で不一致（現状 $cur、定義 $owner:$group $mode）"
        RESULTS+=("$path|$owner|$group|$mode|エラー（作成後の確認で不一致）"); N_ERROR=$((N_ERROR+1))
    fi
done

#---------------------------------------------------------------- 2. 結果一覧
log ""
log "---- 2. 結果一覧 ----"
printf '%-70s %-10s %-10s %-5s %s\n' "PATH" "OWNER" "GROUP" "MODE" "STATUS"
for r in "${RESULTS[@]}"; do IFS='|' read -r a b c d e <<<"$r"; printf '%-70s %-10s %-10s %-5s %s\n' "$a" "$b" "$c" "$d" "$e"; done
log ""
if [ "$DRY_RUN" -eq 1 ]; then lbl="作成予定"; else lbl="作成"; fi
info "対象 ${#DIRS[@]} 件: ${lbl} ${N_CREATED} / 既存 ${N_EXISTS}（うち差異あり ${N_DIFF}） / スキップ ${N_SKIP} / エラー ${N_ERROR}"
if [ "${#REPLACED[@]}" -gt 0 ]; then info "所有者 weblogic → ${APP_OWNER} に置き換えた行: ${#REPLACED[@]} 件（上の [REPLACED] 参照）"; fi
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    info "SELinux が $(getenforce) のため、作成後に restorecon -Rv /disk1 /disk2 を実行してください（/disk1/httpd/logs は semanage fcontext -a -t httpd_log_t の登録後）【要確認】"
fi
if [ "$RC" -eq 0 ]; then info "完了（エラーなし）"; else error "エラー／スキップがあります。上記 [ERROR] を確認してください。"; fi
exit "$RC"


#=============================================================================
# 【要確認】一覧
#   1. weblogic → tomcat の置き換え（APP_OWNER=tomcat）。置き換える場合は所有者名のみ変更し、パスは変更しない。
#   2. WebLogic 専用パス（/disk1/weblogic 配下 3 件、/disk1/job/weblogic 配下 7 件、/disk1/job/os/result/weblogic_01・02、
#      /opt/oracle 配下 3 件）を Tomcat 環境で作成するか、読み替えるか（ディスク構成 ver3 の読み替え表を参照）。
#   3. 用途（備考）が定義書に無いディレクトリの用途。
#   4. マウントポイント（/disk1、/disk2）とファイルシステム・容量（定義書に列が無い）。
#   5. グループ webadmin の GID（「OSユーザ一覧」に定義なし）。未作成なら tomcat:webadmin の行はスキップされる。
#   6. 777 のディレクトリ（セキュリティ強化の観点での見直し）。
#   7. SELinux の方針と、/disk1 配下のコンテキスト（restorecon、httpd_log_t）。
#   8. /work/OS/iptables（firewalld 移行後の要否）、/usr/local/lib/aws 配下（AWS CLI インストーラとの作成順序）。
#   9. /home/weblogic（tomcat）は useradd -m で作成される想定。本スクリプトとの順序。
#=============================================================================
