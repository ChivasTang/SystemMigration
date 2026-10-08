# AP サーバ（RHEL 8.10）ユーザ・グループ設計説明

- プロジェクト：処理用DB老朽化対応（セキュリティ強化）
- 対象：AP サーバ RHEL 5.4 → RHEL 8.10 移行、WebLogic 10.3.4 → Tomcat 9.0.122 置き換え
- 版数：ver1（2026/10/08）
- 根拠資料：`AP\環境定義書(icwaq01w).xlsx`「OSユーザ一覧」「ディレクトリ一覧」「services」「cronrtab」、`AP\環境定義書(icwah01w).xlsx`「OSユーザ一覧」、`AP\APサーバ構築手順書_1.xlsx`「OS環境設定」（RHEL 9 実績ログ）
- 凡例：資料・公式情報で確認できなかった点は【要確認】と記載し、推測で確定していない。

---

## 0. 結論（要約）

| 項目 | 推奨 | 理由 |
|---|---|---|
| tomcat ユーザの UID／主グループ | **UID 700／oinstall（GID 600）を weblogic から引き継ぐ（案 A）** | 既存ファイル・ディレクトリの所有権（数値 ID）がそのまま有効で chown が不要。oinstall を共有する cm_usr／pportal／pprel への影響が出ない。 |
| ホームディレクトリ | `/home/tomcat`（権限 700、所有者 tomcat:oinstall） | 現行 `/home/weblogic`（weblogic:oinstall 700）の読み替え。 |
| ログインシェル | `/bin/bash`（現行 weblogic と同じ）。`/sbin/nologin` 化はセキュリティ方針に応じて【要確認】 | 現行は対話利用あり（services の vncserver2 が weblogic 用）。影響回避を優先。 |
| 作成順序 | グループ（oinstall → pfusr → ftpuser → OP →【要確認】webadmin）→ ユーザ（tomcat → cm_usr → pportal → pprel → pfusr → ftpunyo → opuser） | useradd の `-g` に指定するグループが先に必要。 |
| 既存ファイルの chown | 案 A では原則不要（`find -nouser -o -nogroup` で確認のみ）。`/home/weblogic` を移送する場合のみ `/home/tomcat` へ `chown -R tomcat:oinstall` | 数値 ID を保持して移送（tar -p／rsync -a）すれば UID 700＝tomcat として認識される。 |
| ksh | `dnf install -y ksh`（RHEL 8.10：ksh-20120801-270.el8_10）を useradd より前に実施 | cm_usr／pportal／pprel のログインシェル `/bin/ksh` に必要。 |

---

## 1. RHEL 8.10 での各ユーザ・グループの作成方法

### 1.1 方針

1. **グループを先、ユーザを後**に作成する（`useradd -g` に指定する主グループが存在している必要があるため）。
2. UID／GID は環境定義書の値を `-u`／`-g` で**明示指定**する（RHEL 8.10 の自動採番は 1000 以降のため、指定しないと現行と異なる ID になる）。
3. ホームディレクトリ・ログインシェルも環境定義書の値を `-d`／`-s` で明示指定し、`-m` でホームディレクトリを作成する。
4. 補助グループ（`-G`）・GECOS（`-c`）・パスワードは環境定義書に記載がないため指定しない（補助グループは 2.2 の webadmin の件を【要確認】）。
5. 作成後は `getent group`／`getent passwd` で定義書と突き合わせる。

### 1.2 グループ作成コマンド（groupadd）

```bash
groupadd -g 600  oinstall
groupadd -g 2200 pfusr
groupadd -g 2500 ftpuser
groupadd -g 2510 OP
# 「ディレクトリ一覧」で所有グループに使われているが「OSユーザ一覧」に定義がないグループ（GID 不明）
groupadd -g <webadminのGID> webadmin        # 【要確認】要否・GID（現行機で getent group webadmin を取得）
# 依頼のユーザ一覧には無いが環境定義書「OSユーザ一覧」に定義があるグループ
groupadd -g 501  cpbackup                   # 【要確認】作成要否
```

### 1.3 ユーザ作成コマンド（useradd）

推奨案（案 A：tomcat が weblogic の UID 700／oinstall を引き継ぐ）の例。

```bash
useradd -u 700  -g oinstall -d /home/tomcat  -m -s /bin/bash tomcat
useradd -u 2100 -g oinstall -d /home/cm_usr  -m -s /bin/ksh  cm_usr
useradd -u 2101 -g oinstall -d /home/pportal -m -s /bin/ksh  pportal   # 本番定義書に無し【要確認】
useradd -u 2102 -g oinstall -d /home/pprel   -m -s /bin/ksh  pprel     # 本番定義書に無し【要確認】
useradd -u 2200 -g pfusr    -d /home/pfusr   -m -s /bin/bash pfusr
useradd -u 2500 -g ftpuser  -d /home/ftpunyo -m -s /bin/bash ftpunyo
useradd -u 2510 -g OP       -d /home/opuser  -m -s /bin/bash opuser
useradd -u 501  -g cpbackup -d /home/cpbackup -m -s /bin/bash cpbackup  # 【要確認】作成要否
```

- `-m`：`/etc/skel` を複製してホームディレクトリを作成する。権限は `/etc/login.defs` の `UMASK 077` により **0700** になる（現行の `/home/weblogic` も 700 で一致）。
- `-s /bin/ksh`：useradd はシェルの実在を検証しないため、ksh 未導入でもユーザは作成できるが、ログインできない。**useradd の前に `dnf install -y ksh` を実施**し、`/etc/shells` に `/bin/ksh` が登録されることを確認する。
- UID 501／600／700 は RHEL 8.10 の「システムアカウント範囲（201～999）」に入る。`-u` で明示指定すれば作成できる（3.1 参照）。
- パスワードは `passwd <ユーザ名>` で設定する（値は＜別途管理＞。鍵認証のみとする場合は不要【要確認】）。

### 1.4 作成後の確認コマンド

```bash
getent group oinstall pfusr ftpuser OP
getent passwd tomcat cm_usr pportal pprel pfusr ftpunyo opuser
ls -ld /home/tomcat /home/cm_usr /home/pportal /home/pprel /home/pfusr /home/ftpunyo /home/opuser
for u in tomcat cm_usr pportal pprel pfusr ftpunyo opuser; do LC_ALL=C passwd -S $u; done
ls -l /bin/bash /bin/ksh
```

---

## 2. tomcat ユーザの設計

### 2.1 UID／GID：引き継ぎ案と新規採番案の比較

| 観点 | 案 A：weblogic の ID を引き継ぐ<br>（UID 700／主グループ oinstall GID 600） | 案 B：新規採番<br>（例：`useradd -r` でシステム範囲の空き ID、または UID/GID 1000 以降＋専用グループ tomcat） |
|---|---|---|
| 既存ファイル・ディレクトリの所有権 | 数値 ID を保持して移送（`tar -p`、`rsync -a`）すれば UID 700 は自動的に tomcat として表示される。**chown 不要** | UID 700 のファイルはすべて chown が必要（`/disk1/kq` 配下、`/disk1/weblogic`、`/disk1/hyojun`、`/home/weblogic` など、ディレクトリ一覧で weblogic 所有のもの約 120 ディレクトリ＋配下ファイル） |
| cm_usr／pportal／pprel との共有 | 主グループ oinstall（GID 600）を共有するため、`/disk1/kq` 配下（グループ oinstall）の読み書きが現行どおり | 専用グループにすると oinstall のグループ権限が効かなくなる。oinstall を補助グループ（`-G oinstall`）に付ければ読み書きはできるが、tomcat が新規作成するファイルの所有グループが oinstall でなくなる |
| 他サーバとの整合 | DB サーバ側でも oinstall（GID 600）が使われている（Oracle 標準の oinstall）。ID 体系を変えない | AP サーバだけ ID 体系が変わる |
| セキュリティ | 「weblogic」という名前を廃止し tomcat に改名する効果は同じ。UID 700 は RHEL 8 ではシステムアカウント範囲（201～999）であり、サービスアカウントとして妥当 | 同上。新規採番でも強度は変わらない |
| 作業量・リスク | 小（useradd 1 回）。移送後に `find -nouser -o -nogroup` で確認するだけ | 大（chown の対象漏れ、スクリプト内の `chown weblogic` 等の修正、切り戻し時の再 chown） |
| RHEL 8 との整合 | `useradd -u 700` は範囲外警告が出る場合があるが作成される（3.1 参照）。パッケージ付属アカウントは 999 から降順に採番されるため 700 と衝突する可能性は低いが、作成前に `getent passwd 700` で未使用を確認する | 新規 ID は衝突の心配がない |

**推奨：案 A（UID 700／oinstall を引き継ぎ、ユーザ名のみ tomcat にする）。**
理由：本移行の方針「それ以外の機能（cm_usr、pportal、pprel、pfusr、ftpunyo、opuser）への影響は避ける」に最も合致し、`/disk1/kq` 配下のグループ共有・既存データの所有権・DB サーバとの ID 整合を保てるため。

案 A の留意点：
- 【要確認】現行機の `/usr/share/doc/setup/uidgid`（RHEL 8 の予約 ID 一覧）に 700／600 が無いことは確認したうえで、新環境で `getent passwd 700`／`getent group 600` が空であることを事前確認する。
- 【要確認】weblogic ユーザが現行機で補助グループ（webadmin など）を持っていたか（`id weblogic`）。ディレクトリ一覧には weblogic:webadmin のディレクトリ（`/disk1/hyojun` 配下、`/disk1/kq/pf/seinou`）があるため、tomcat にも同じ補助グループが必要な可能性が高い。

### 2.2 oinstall（GID 600）との関係、ファイル権限・グループ共有・ディレクトリ所有者の整合

環境定義書「OSユーザ一覧」では weblogic／cm_usr／pportal／pprel の 4 ユーザが主グループ oinstall（GID 600）を共有している。「ディレクトリ一覧」の所有者・グループ・権限は次のとおり（抜粋）。

| ディレクトリ | 所有者:グループ | 権限 | 備考（定義書） | 移行後の読み替え |
|---|---|---|---|---|
| /disk1/kq | weblogic:oinstall | 777 | — | tomcat:oinstall（本番定義書では root:root 777【要確認】） |
| /disk1/kq/cm 配下（pportal 関連） | weblogic:oinstall | 777 | ポータル用。QA のみ | tomcat:oinstall |
| /disk1/kq/cm/release 配下 | pprel:oinstall | 777 | リリースサーバ用。QA のみ | 変更なし |
| /disk1/kq/pf 配下 | pfusr:pfusr | 777 | 性能チーム | 変更なし |
| /disk1/kq/pf/seinou | weblogic:webadmin | 777 | — | tomcat:webadmin【要確認】 |
| /disk1/weblogic、/disk1/weblogic/projects | weblogic:oinstall | 755 | WebLogic ディレクトリ（WebLogic設計書参照） | Tomcat インスタンス用ディレクトリへ読み替え（名称・配置は【要確認】） |
| /disk1/weblogic/logs | weblogic:oinstall | 777 | — | 同上 |
| /disk1/hyojun 配下 | weblogic:webadmin | 775／755 | war 退避・リリース | tomcat:webadmin【要確認】 |
| /opt/oracle／middleware／wlserver_10.3 | weblogic:oinstall | 755／750／755 | WebLogic インストール先 | 作成しない（Tomcat は別途導入）【要確認】 |
| /home/weblogic | weblogic:oinstall | 700 | — | /home/tomcat（tomcat:oinstall 700） |
| /home/weblogic/add_on | weblogic:oinstall | 755 | リリース作業用 | /home/tomcat/add_on【要確認】 |

整合のポイント：
1. **グループ共有**：tomcat の主グループを oinstall にすれば、`/disk1/kq` 配下の oinstall グループ権限（現行は 777 のため実質的に全員が読み書き可能）は現行どおり。
2. **Tomcat が作成するファイルの権限**：Tomcat 9 の `catalina.sh` は既定で `UMASK=0027` を設定するため、Tomcat が作成するファイルは 640／750 になる。cm_usr／pportal／pprel（oinstall）は読めるが**書けない**。現行 WebLogic は起動シェルの umask（RHEL 5 の `/etc/profile` では UID 700＝グループ名≠ユーザ名のため 022）で動作していたと考えられ、他ユーザが Tomcat の出力ファイルを更新する運用がある場合は `setenv.sh` で `UMASK=0022` または `0002` にする必要がある【要確認】。
3. **777 の見直し**：定義書の 777 はセキュリティ強化の観点では過大だが、本設計では定義書の値を転記し、見直しは別途【要確認】とする（アプリケーションの書き込み先を把握してから絞る）。
4. **webadmin**：GID が定義書に無い。現行機の `getent group webadmin` で GID と所属メンバーを取得し、同じ GID で作成する【要確認】。
5. **本番定義書との差**：本番（icwah01w）では `/disk1/kq` と `/disk1/hyojun/.../bean/comgr*` 等が root:root。QA と本番で所有者が異なるため、環境ごとに「ディレクトリ一覧」の値を使う【要確認】。

### 2.3 ホームディレクトリ・ログインシェル

| 項目 | 設定値 | 根拠・備考 |
|---|---|---|
| ホームディレクトリ | `/home/tomcat` | 現行 `/home/weblogic` の読み替え。`useradd -m` で作成し、権限は 700（定義書の /home/weblogic と同じ） |
| 所有者:グループ | tomcat:oinstall | 定義書の weblogic:oinstall の読み替え |
| 配下ディレクトリ | `/home/tomcat/add_on`（755） | 定義書 `/home/weblogic/add_on`（リリース作業用）の読み替え。要否は【要確認】 |
| ログインシェル | `/bin/bash` | 定義書の weblogic と同じ。services 一覧に weblogic 用 VNC（vncserver2 5902/tcp）があり対話利用が想定されるため維持。セキュリティ強化として `/sbin/nologin`（起動は systemd、作業は `sudo -u tomcat` または `runuser -u tomcat`）にするかは【要確認】 |
| パスワード | ＜別途管理＞ | nologin にする場合は不要 |
| 環境変数 | JAVA_HOME／CATALINA_HOME 等 | tomcat の `~/.bash_profile` ではなく Tomcat の `setenv.sh`／systemd ユニットの `Environment=` で与える（Tomcat シートで扱う） |

### 2.4 既存ファイルの所有者変更（chown）の対象と手順

#### 案 A（推奨：UID 700 引き継ぎ）の場合
1. 旧サーバからのデータ移送は数値 ID を保持する方法（`tar -cpf`／`tar -xpf`、`rsync -a --numeric-ids`）で行う。
2. 移送後に所有者不明のファイルが無いことを確認する（空であること）。
   ```bash
   find /disk1 /disk2 /home -xdev \( -nouser -o -nogroup \) -ls
   ```
3. ホームディレクトリは `useradd -m` で作成した `/home/tomcat` に旧 `/home/weblogic` の内容を移す場合のみ、所有者を揃える。
   ```bash
   chown -R tomcat:oinstall /home/tomcat
   chmod 700 /home/tomcat
   ```
4. 名前で参照している箇所（スクリプト内の `chown weblogic`、`su - weblogic`、cron の実行ユーザ等）を洗い出す【要確認】。
   ```bash
   grep -rIl "weblogic" /disk1/job /etc/cron* /etc/systemd/system 2>/dev/null
   ```

#### 案 B（新規採番）を採る場合の chown
対象（ディレクトリ一覧で所有者 weblogic のもの）：`/disk1/kq` とその配下（pprel／pfusr 所有を除く）、`/disk1/weblogic` 配下、`/disk1/hyojun` 配下、`/home/weblogic`（→ `/home/tomcat`）、`/opt/oracle` 配下（WebLogic 用のため移行しない想定）。

手順（数値 ID で対象を特定し、シンボリックリンク自体も対象にする）：
```bash
# 1) 事前にサービスを停止し、現状の所有者一覧を退避（切り戻し用）
find /disk1 /disk2 /home -xdev -uid 700 -printf '%u %g %m %p\n' > /work/chown_before_<日付>.txt
# 2) UID 700 のファイルを新しい tomcat ユーザへ（グループは oinstall のまま）
find /disk1 /disk2 /home -xdev -uid 700 -exec chown -h tomcat {} +
# 3) 主グループも変える場合（cm_usr／pportal／pprel に影響するため非推奨）
find /disk1 /disk2 /home -xdev -gid 600 -exec chgrp -h <新グループ> {} +
# 4) 確認
find /disk1 /disk2 /home -xdev \( -nouser -o -nogroup \) -ls
```
SELinux を enforcing にする場合は chown 後に `restorecon -R /disk1 /disk2 /home/tomcat` も実施する。

---

## 3. RHEL 5.4 → 8.10 の差異と注意点

### 3.1 UID／GID の範囲
| 項目 | RHEL 5.4 | RHEL 8.10 | 影響 |
|---|---|---|---|
| UID_MIN／GID_MIN（自動採番の開始） | 500 | 1000 | 定義書の 501（cpbackup）、600（oinstall）、700（weblogic→tomcat）は RHEL 8 ではシステムアカウント範囲。`-u`／`-g` を明示すれば作成できる。指定を省略すると 1000 以降が採番され現行と不一致になる |
| SYS_UID_MIN～SYS_UID_MAX | （RHEL 5 の login.defs に定義なし。500 未満が予約） | 201～999 | パッケージ付属アカウント（`useradd -r`）は 999 から降順に採番。700 と衝突する可能性は低いが事前に `getent passwd 700` で確認 |
| 範囲外 UID の警告 | なし | `useradd warning: tomcat's uid 700 outside of the UID_MIN 1000 and UID_MAX 60000 range.` が表示される場合がある（Red Hat KB 7046625 は RHEL 9 の事例。RHEL 8.10 の shadow-utils での表示有無は【要確認】） | 警告のみでユーザは作成される。期待結果に「警告が出ても可」と明記する |
| nobody | UID 99（nfsnobody 4294967294 あり） | UID 65534（nfsnobody は廃止） | 定義書の nobody／nfsnobody は作成しない |

### 3.2 /etc/login.defs の既定値
| 設定 | RHEL 5.4（既定） | RHEL 8.10（既定） | 備考 |
|---|---|---|---|
| UID_MIN／UID_MAX | 500／60000 | 1000／60000 | 上記 |
| GID_MIN／GID_MAX | 500／60000 | 1000／60000 | 上記 |
| SYS_UID_MIN／SYS_UID_MAX | なし | 201／999 | RHEL 7 以降 |
| UMASK | 077 | 077 | `useradd -m` のホームディレクトリ権限は両方とも 0700（RHEL 9 以降は HOME_MODE 0700 で明示） |
| CREATE_HOME | yes | yes | `-m` を付けなくても作成されるが、本手順では明示する |
| USERGROUPS_ENAB | yes | yes | `-g` を省略するとユーザ名と同名のグループが自動作成される。本手順では `-g` を明示 |
| パスワードハッシュ | MD5_CRYPT_ENAB yes（既定は MD5 `$1$`。authconfig で SHA-512 に変更している場合あり） | ENCRYPT_METHOD SHA512（`$6$`） | 旧 `/etc/shadow` のハッシュをそのまま移送しても RHEL 8 で認証はできるが、MD5 は弱いため新環境で `passwd` により再設定することを推奨【要確認】 |
| PASS_MIN_LEN | 5 | 5（ただし RHEL 8 は pam_pwquality が優先。既定 minlen 8、辞書・類似チェックあり。root の設定時は警告のみ） | 初期パスワードの長さ・複雑さの基準は【要確認】 |
| PASS_MAX_DAYS 等 | 99999 | 99999 | 有効期限の方針は【要確認】 |

実機の `/etc/login.defs` の値は構築時に `grep -E '^(UID_|GID_|SYS_UID|SYS_GID|UMASK|HOME_MODE|ENCRYPT)' /etc/login.defs` で確認する（ユーザ・グループシートの事前確認に組み込み）。

### 3.3 useradd の既定動作
- `/etc/default/useradd`（GROUP=100、HOME=/home、SHELL=/bin/bash、SKEL=/etc/skel、CREATE_MAIL_SPOOL=yes）は RHEL 5／8 で同じ。`/var/spool/mail/<ユーザ名>` が作成される。
- RHEL 8 の useradd は `/etc/subuid`／`/etc/subgid`（コンテナ用の従属 ID 範囲）にもエントリを追加する。運用上の影響はない。
- `-m` で `/etc/skel` の `.bash_profile`／`.bashrc`／`.bash_logout` が複製される。ksh ユーザ（cm_usr 等）の `.profile`／`.kshrc` は skel に無いため、現行のものを移送する【要確認】。
- RHEL 7 以降は `/bin` → `/usr/bin` のシンボリックリンク（UsrMove）。定義書のシェルパス `/bin/bash`、`/bin/ksh` はそのまま有効（`/etc/shells` には `/bin/ksh` と `/usr/bin/ksh` の両方が登録される）。
- SELinux が有効な場合、useradd はユーザを既定の SELinux ユーザ（unconfined_u）に対応付ける。`-Z` での個別指定は行わない。

### 3.4 ksh の導入
- RHEL 5 の `/bin/ksh` は AT&T ksh93（ksh-2008xxxx 系）。RHEL 8.10 は `ksh-20120801-270.el8_10`（ksh93、2025-11-04 の RHBA-2025:19571 が最新）。同じ ksh93 系だが版が異なるため、cm_usr／pportal／pprel のシェルスクリプトは新環境で動作確認する【要確認】。
- 導入：`dnf install -y ksh`。導入後 `rpm -q ksh`、`ls -l /bin/ksh`、`grep ksh /etc/shells` で確認する。リポジトリ（RHUI か Satellite か、BaseOS／AppStream のどちらで提供されるか）は新環境のリポジトリ構成に依存するため【要確認】。
- mksh／pdksh は別パッケージ（互換性が異なる）。定義書の `/bin/ksh` には ksh パッケージを使う。

### 3.5 SELinux
- RHEL 5.4 の既定も enforcing（targeted）だが、現行機の設定は資料に無い【要確認】。参照元（APサーバ構築手順書_1.xlsx の RHEL 9 実績）は `SELINUX=disabled`。
- RHEL 8.10 で enforcing とする場合：useradd -m のホームは正しいラベル（user_home_dir_t）で作成されるが、tar 等で移送した `/disk1` 配下や `/home/tomcat` へ移した旧データは `restorecon -R` が必要。Tomcat を `/usr/local` 等の非標準パスに置いて systemd から起動する場合はラベル initrc_t／unconfined で動作するため Tomcat 自体の制約は少ないが、Apache（httpd_t）から Tomcat の HTTP ポートへ中継するには `setsebool -P httpd_can_network_connect on` 等が必要（Apache シートで扱う【要確認】）。
- RHEL 8 では `/etc/selinux/config` の `SELINUX=disabled` が有効（RHEL 9 以降はカーネル引数 `selinux=0` が必要）。方針は OS環境設定シートで【要確認】。

### 3.6 systemd 管理
- RHEL 5 は SysV init（`/etc/init.d`、chkconfig）。現行の WebLogic／Apache は `/disk1/job/weblogic/scripts/wl_*_start.sh`、`/disk1/job/apache/scripts/apache_*.sh` を root の cron（日曜停止・月曜起動）から呼ぶ運用（環境定義書「cronrtab」）。
- RHEL 8 では Tomcat インスタンス（ap01～ap06）を systemd ユニット（例：`tomcat@.service`、`User=tomcat`、`Group=oinstall`、`UMask=`、`LimitNOFILE=`）で管理し、`systemctl enable --now tomcat@ap01` のように起動・自動起動を設定する。`su - tomcat -c startup.sh` 形式は systemd の cgroup 外で動くため採用しない。cron の起動停止スクリプトは `systemctl start/stop tomcat@apNN` へ書き換える【要確認】。
- `User=` に指定するアカウントはブート時に存在している必要がある（ローカルアカウントのため問題なし）。tomcat を `/sbin/nologin` にしても systemd からの起動には影響しない。
- VNC（services の vncserver2＝weblogic 用 5902/tcp）は RHEL 8 では tigervnc の `vncserver@.service` 方式に変わる。tomcat 用に継続するかは【要確認】。

### 3.7 その他の差異
- 認証設定は authconfig から **authselect** に変更（`/etc/pam.d/system-auth` を直接編集しない）。パスワード品質は pam_pwquality、ロックアウトは pam_faillock（既定無効）。
- **crypto-policies**（RHEL 8）はローカルアカウント作成には影響しないが、各ユーザの `~/.ssh/authorized_keys` を移送する場合、DEFAULT ポリシーでは 2048bit 未満の RSA 鍵や ssh-dss 鍵は拒否される【要確認】。
- パッケージ付属アカウントの差：ntp → chrony（ユーザ chrony）、nfsnobody 廃止、haldaemon／sabayon／distcache／gopher 等は RHEL 8 に存在しない。定義書のこれらは作成しない。
- `nscd` は RHEL 8 では非推奨（sssd）。ローカルアカウントのみの構成では不要。

---

## 4. 【要確認】一覧（本設計）

| No. | 項目 | 内容 |
|---|---|---|
| 1 | webadmin グループ | 「ディレクトリ一覧」で使用されているが GID の定義が無い。現行機で `getent group webadmin`、`id weblogic` を取得し、要否・GID・メンバーを確定する |
| 2 | cpbackup | 依頼のユーザ一覧に無いが環境定義書「OSユーザ一覧」に定義あり（/disk1/job/comn 等の所有者）。作成要否 |
| 3 | pportal／pprel | 本番定義書（icwah01w）に無い。本番環境での作成要否 |
| 4 | tomcat のログインシェル | /bin/bash（現行踏襲）か /sbin/nologin（セキュリティ強化）か |
| 5 | tomcat の補助グループ | webadmin を付与するか（No.1 に依存） |
| 6 | Tomcat の umask | catalina.sh 既定 0027 のままで他ユーザ（oinstall）の書き込み要否に支障がないか |
| 7 | 777 ディレクトリ | 定義書の 777 を踏襲するか、セキュリティ強化で絞るか |
| 8 | パスワード運用 | パスワード認証の要否、初期パスワードの基準、旧 /etc/shadow のハッシュを移送するか再設定するか |
| 9 | UID 700／GID 600 の未使用確認 | 新環境で `getent passwd 700`、`getent group 600` が空であること |
| 10 | ksh の提供リポジトリ | 新環境のリポジトリ構成（RHUI／Satellite、BaseOS／AppStream） |
| 11 | ksh スクリプト互換 | cm_usr／pportal／pprel のスクリプトが ksh-20120801 で動作するか |
| 12 | SELinux の方針 | enforcing／permissive／disabled |
| 13 | WebLogic 用ディレクトリ | /disk1/weblogic、/disk1/job/weblogic、/opt/oracle、/home/weblogic/add_on の読み替え先・要否 |
| 14 | 名前参照の洗い出し | スクリプト・cron 内の「weblogic」文字列の置き換え範囲 |
| 15 | useradd の範囲外警告 | RHEL 8.10 の shadow-utils で表示されるか（表示されても作成はされる） |

## 5. 参照した公式情報
- Red Hat: Configuring basic system settings (RHEL 8) – Managing users and groups（予約 ID は 1000 未満、UID_MIN／GID_MIN の既定 1000）
  https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/managing-users-and-groups_configuring-basic-system-settings
- Red Hat Errata RHBA-2025:19571（ksh-20120801-270.el8_10、RHEL 8 向け、2025-11-04）
  https://access.redhat.com/errata/RHBA-2025:19571
- Red Hat KB 7046625（useradd の UID 範囲外警告。RHEL 9 の事例）
  https://access.redhat.com/ja/solutions/7046625
- login.defs(5) man page（UID_MIN／SYS_UID_MIN／UMASK／HOME_MODE 等の意味）
  https://man.archlinux.org/man/login.defs.5.en
