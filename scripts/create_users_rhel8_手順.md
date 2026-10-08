# RHEL 8.10 ユーザ・グループ作成スクリプト 実行手順（create_users_rhel8.sh）

- プロジェクト：処理用DB老朽化対応（セキュリティ強化）／AP サーバ（RHEL 8.10）
- 版数：ver1（2026/10/08）
- 対象：グループ 5 件（cpbackup、oinstall、pfusr、ftpuser、OP）、ユーザ 6 件（cpbackup、weblogic（または tomcat）、cm_usr、pfusr、ftpunyo、opuser）
- 注意：**本番環境で実行する前に、検証環境（qa）で動作を確認する。** スクリプトはユーザ・グループ・ホームの削除、既存ユーザ・グループの変更を行わない。

## 1. スクリプトの動作
| 処理 | 内容 | 結果表示 |
|---|---|---|
| 0. 事前確認 | root 確認、OS 表示、/etc/login.defs から採番範囲（SYS_UID/UID/SYS_GID/GID の MIN/MAX）を読み込み | [INFO] |
| 1. グループ | `getent group <名前>` → 存在すれば作成せず既存 GID を使用（参考値と不一致なら【要確認】表示）。無ければ `getent group <GID>` で参考 GID の使用状況を確認し、未使用なら参考値で、使用済みなら同じ範囲の次の空き番号で `groupadd -g` | [EXISTS]／[CREATED]／[CHANGED]／[ERROR] |
| 2. シェル | /bin/ksh が必要なユーザがあり未導入なら `dnf install -y ksh`。/bin/bash・/bin/ksh の存在と /etc/shells 登録を確認 | [INFO]／[CREATED]／[ERROR] |
| 3. ユーザ | `id <名前>` → 存在すれば作成せず `id`・`getent passwd` を表示し、定義（UID／グループ／ホーム／シェル）との差異を報告。無ければ `getent passwd <UID>` で重複確認し、`useradd -u -g -d -m -s -c` で作成（UID 使用済みなら同じ範囲の次の空き番号） | [EXISTS]／[CREATED]／[CHANGED]／[SKIP]／[ERROR] |
| 4. 確認 | 各ユーザで `su - <名前> -c 'id; echo $SHELL; pwd'`、bash は ~/.bash_profile・~/.bashrc、ksh は ~/.profile を表示。`ls -la ~` と /etc/skel 配布ファイルの有無を確認 | 一覧表示 |
| 5. 結果 | グループ・ユーザの確認結果一覧（名前、UID、GID、グループ、ホーム、シェル、状態）と `getent passwd` を表示 | 終了コード 0（エラーなし）／1（[ERROR] あり） |

- パスワードは設定しない（useradd 直後はパスワードロック＝パスワードログイン不可。鍵認証は可）。
- `--dry-run`（または `-n`）を付けると、groupadd／useradd／dnf を実行せず判定結果だけを表示する。
- `APP_USER_NAME=tomcat` を環境変数で渡すと、weblogic の代わりに tomcat（UID 700／oinstall／/home/tomcat／bash）を作成する【要確認】。

## 2. 実行手順
| No. | 区分 | 作業 | コマンド | 期待結果 |
|---|---|---|---|---|
| 1 | 事前確認 | スクリプトを作業ディレクトリに転送し、改行コードが LF・文字コードが UTF-8 であることを確認する | `file create_users_rhel8.sh` | 「Bourne-Again shell script, UTF-8 Unicode text executable」（CRLF の場合は `sed -i 's/\r$//' create_users_rhel8.sh`） |
| 2 | 事前確認 | 構文確認 | `bash -n create_users_rhel8.sh` | 何も表示されない |
| 3 | 事前確認 | root になる | `sudo -i` | プロンプトが # になる |
| 4 | 事前確認 | 現状のアカウントを退避（切り戻し・比較用） | `cp -p /etc/passwd /etc/passwd.$(date +%Y%m%d); cp -p /etc/group /etc/group.$(date +%Y%m%d); cp -p /etc/shadow /etc/shadow.$(date +%Y%m%d)` | 何も表示されない |
| 5 | 事前確認 | dry-run で判定結果を確認する（変更なし） | `bash create_users_rhel8.sh --dry-run` | [PLAN]／[DRY-RUN] の内容が定義どおり。[CHANGED] があれば変更後の UID/GID を記録し、採用可否を判断する【要確認】 |
| 6 | 作業 | 本実行（ログを保存） | `bash create_users_rhel8.sh 2>&1 \| tee /var/tmp/create_users_$(date +%Y%m%d_%H%M%S).log` | [ERROR] が無く、最終行が「[INFO] 完了（エラーなし）」 |
| 7 | 事後確認 | 冪等性の確認（再実行で変更が無いこと） | `bash create_users_rhel8.sh --dry-run` | すべて [EXISTS]、[PLAN]／[CHANGED] が無い |
| 8 | 事後確認 | 一覧の確認 | `getent group cpbackup oinstall pfusr ftpuser OP; getent passwd cpbackup weblogic cm_usr pfusr ftpunyo opuser` | 5 グループ・6 ユーザが表示され、UID/GID が結果一覧と一致する（weblogic→tomcat 置き換え時は tomcat） |
| 9 | 事後確認 | ホームディレクトリの権限 | `ls -ld /home/cpbackup /home/weblogic /home/cm_usr /home/pfusr /home/ftpunyo /home/opuser` | 所有者＝ユーザ、グループ＝プライマリグループ、権限 drwx------（700） |
| 10 | 事後確認 | ksh の確認 | `rpm -q ksh; ls -l /bin/ksh; grep ksh /etc/shells; su - cm_usr -c 'echo ${.sh.version}'` | ksh-20120801-xxx.el8、/bin/ksh が存在、/etc/shells に登録、ksh93 の版が表示される |
| 11 | 作業（任意） | パスワード設定（必要な場合のみ） | `passwd <ユーザ名>` → `<パスワード>` を入力 | 「all authentication tokens updated successfully.」 |
| 12 | 切り戻し | （作成したものを取り消す場合のみ、作業責任者の判断で手動実行。スクリプトは削除しない） | `userdel -r <ユーザ名>` ／ `groupdel <グループ名>` | 対象が存在しないこと |

## 3. 確認結果の一覧（実行前の計画値。実行後はスクリプト末尾の一覧で確定する）
| ユーザ名 | UID（参考値） | GID（参考値） | プライマリグループ | ホーム | シェル | 状態（予定） |
|---|---|---|---|---|---|---|
| cpbackup | 501 | 501 | cpbackup | /home/cpbackup | /bin/bash | 未実施（参考値が未使用なら参考値で作成） |
| weblogic（置換時 tomcat） | 700 | 600 | oinstall | /home/weblogic（/home/tomcat） | /bin/bash | 未実施（同上。tomcat 置換は【要確認】） |
| cm_usr | 2100 | 600 | oinstall | /home/cm_usr | /bin/ksh | 未実施（ksh 未導入なら dnf で導入後に作成） |
| pfusr | 2200 | 2200 | pfusr | /home/pfusr | /bin/bash | 未実施 |
| ftpunyo | 2500 | 2500 | ftpuser | /home/ftpunyo | /bin/bash | 未実施 |
| opuser | 2510 | 2510 | OP | /home/opuser | /bin/bash | 未実施 |

状態の表記（スクリプト出力）：作成（参考値どおり）／作成（UID 変更 旧 → 新）／既存（定義どおり）／既存（差異：…【要確認】）／スキップ（理由）／エラー（理由）

## 4. 【要確認】一覧
| No. | 項目 | 内容 |
|---|---|---|
| 1 | cpbackup の備考 | 備考「cpbackup」の意味が不明。GECOS（-c）にそのまま転記した。用途は /disk1/job/comn（共通 PF バックアップ）の所有者であること以外不明 |
| 2 | weblogic → tomcat | 置き換えるか。置き換える場合は `APP_USER_NAME=tomcat` で実行（ユーザ名のみ変更、UID 700／oinstall は同じ）。weblogic が既に存在するサーバで実行すると UID 700 が使用済みと判定され 701 になる |
| 3 | UID/GID の範囲 | cpbackup 501／oinstall 600／weblogic 700 は RHEL 8 のシステム範囲（201～999）。RHEL 8 推奨の 1000 以上に変更するか、既存データの所有者（数値 ID）引き継ぎを優先して参考値のままにするか |
| 4 | 用途・権限 | cm_usr／ftpunyo／opuser の用途、各ユーザの sudo 権限、umask（RHEL 8 既定：グループ名＝ユーザ名なら 002、それ以外 022）、パスワード期限（login.defs 既定 99999） |
| 5 | 補助グループ | weblogic（tomcat）の webadmin（環境定義書「ディレクトリ一覧」/disk1/hyojun の所有グループ。「OSユーザ一覧」に定義なし）ほか、補助グループの要否 |
| 6 | ksh の環境設定 | /etc/skel に .profile が無いため cm_usr の ~/.profile は作成されない。ksh 用の環境設定ファイルを別途配布するか |
| 7 | パスワード認証 | パスワードを設定しないためパスワードログイン不可。鍵認証のみとするか、`passwd` で設定するか（ftpunyo は FTP 認証方式に依存） |
| 8 | ログインシェル | weblogic（tomcat）を /sbin/nologin にするか（セキュリティ強化） |
| 9 | 既存ユーザの差異 | 実行時に「既存（差異：…）」が出た場合の対応（変更しない方針のため手動対応） |
