# 定義書「ディレクトリ一覧」（環境定義書(icwah01w).xlsx）取り込み一覧

- 件数：145 件（定義書 6～150 行目）
- 状態は実行前のため「未実施」。実行後はスクリプト末尾の結果一覧（作成／既存／スキップ／エラー）で確定する。
- 所有者 weblogic の行は APP_OWNER=tomcat 指定時に所有者名のみ tomcat に置換（【要確認】）。

| No. | 定義書行 | パス | 用途（備考） | 所有者 | グループ | 権限 | 状態 | 注意 |
|---|---|---|---|---|---|---|---|---|
| 1 | 6 | /disk1 | （記載なし）【要確認】 | root | root | 755 | 未実施 | マウントポイント（ディスク構成手順でマウント済みであること。findmnt で確認） |
| 2 | 7 | /disk1/kq | （記載なし）【要確認】 | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 3 | 8 | /disk1/kq/pf | （記載なし）【要確認】 | pfusr | pfusr | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 4 | 9 | /disk1/kq/pf/pfusr | （記載なし）【要確認】 | pfusr | pfusr | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 5 | 10 | /disk1/kq/pf/pfusr/seinou | 性能情報取得用SHELL格納先、性能情報格納先 | pfusr | pfusr | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 6 | 11 | /disk1/kq/pf/pfusr/work | 性能チーム作業用ディレクトリ | pfusr | pfusr | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 7 | 12 | /disk1/kq/pf/seinou | 性能情報取得用SHELL格納先、性能情報格納先 | weblogic | webadmin | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】）；グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 8 | 13 | /disk1/weblogic | Weblogicディレクトリ (※[統合顧客DBシステム WebLogic設計書]を参照) | weblogic | oinstall | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 9 | 14 | /disk1/weblogic/projects | （記載なし）【要確認】 | weblogic | oinstall | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 10 | 15 | /disk1/weblogic/logs | （記載なし）【要確認】 | weblogic | oinstall | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 11 | 16 | /disk1/hyojun | マスタメンテナンス機能リリース | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 12 | 17 | /disk1/hyojun/build_bak | Warファイルの退避ディレクトリ | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 13 | 18 | /disk1/hyojun/build | マスタメンテナンス機能リリース | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 14 | 19 | /disk1/hyojun/build/webapi | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 15 | 20 | /disk1/hyojun/build/webapi/application | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 16 | 21 | /disk1/hyojun/build/webapi/application/WEB-INF | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 17 | 22 | /disk1/hyojun/build/webapi/application/WEB-INF/src | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 18 | 23 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 19 | 24 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 20 | 25 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 21 | 26 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 22 | 27 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 23 | 28 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 24 | 29 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 25 | 30 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 26 | 31 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgr/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 27 | 32 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 28 | 33 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrchgupl/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 29 | 34 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 30 | 35 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcst/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 31 | 36 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 32 | 37 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrcstupl/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 33 | 38 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 34 | 39 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/comgrupl/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 35 | 40 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 36 | 41 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/duty/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 37 | 42 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 38 | 43 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp014/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 39 | 44 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 40 | 45 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp015/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 41 | 46 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 42 | 47 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 43 | 48 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp017/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 44 | 49 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 45 | 50 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp018/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 46 | 51 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 47 | 52 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp019/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 48 | 53 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 49 | 54 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp020/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 50 | 55 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 51 | 56 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp021/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 52 | 57 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 53 | 58 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp022/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 54 | 59 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 55 | 60 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp023/output | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 56 | 61 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 57 | 62 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp024/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 58 | 63 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 59 | 64 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp025/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 60 | 65 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026 | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 61 | 66 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/bean/kqap10imp026/input | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 62 | 67 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 63 | 68 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 64 | 69 | /disk1/hyojun/build/webapi/application/WEB-INF/src/jp/co/fujixerox/kq/ap/webapi/component/logic/common | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 65 | 70 | /disk1/hyojun/build/svc_sts | サービスステータス監視機能リリース | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 66 | 71 | /disk1/hyojun/build/svc_sts/src | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 67 | 72 | /disk1/hyojun/build/svc_sts/src/jp | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 68 | 73 | /disk1/hyojun/build/svc_sts/src/jp/co | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 69 | 74 | /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 70 | 75 | /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq | （記載なし）【要確認】 | root | root | 775 | 未実施 |  |
| 71 | 76 | /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 72 | 77 | /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/handler | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 73 | 78 | /disk1/hyojun/build/svc_sts/src/jp/co/fujixerox/kq/svcsts/util | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 74 | 79 | /disk1/hyojun/build/svc_sts/resource | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 75 | 80 | /disk1/hyojun/build/svc_sts/lib | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 76 | 81 | /disk1/hyojun/svc_sts | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 77 | 82 | /disk1/hyojun/svc_sts/lib | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 78 | 83 | /disk1/hyojun/svc_sts/logs | （記載なし）【要確認】 | weblogic | webadmin | 775 | 未実施 | グループ webadmin は「OSユーザ一覧」に定義がない（未作成なら本行はスキップされる）【要確認】 |
| 79 | 84 | /disk1/httpd | （記載なし）【要確認】 | root | root | 755 | 未実施 |  |
| 80 | 85 | /disk1/httpd/logs | Apacheアクセス・エラーログ格納ディレクトリ | root | root | 700 | 未実施 |  |
| 81 | 86 | /disk1/job | （記載なし）【要確認】 | root | root | 755 | 未実施 |  |
| 82 | 87 | /disk1/job/conf | パラメータファイル格納ディレクトリ | root | root | 755 | 未実施 |  |
| 83 | 88 | /disk1/job/os | os用プログラム格納ディレクトリ | root | root | 755 | 未実施 |  |
| 84 | 89 | /disk1/job/os/file_purge | ファイルパージ処理用ディレクトリ | root | root | 755 | 未実施 |  |
| 85 | 90 | /disk1/job/os/file_purge/scripts | メインプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 86 | 91 | /disk1/job/os/file_purge/sub | サブプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 87 | 92 | /disk1/job/os/file_purge/sql | SQLプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 88 | 93 | /disk1/job/os/file_purge/out | アウトプットファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 89 | 94 | /disk1/job/os/file_purge/tmp | 一時ファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 90 | 95 | /disk1/job/os/file_purge/result | 結果ファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 91 | 96 | /disk1/job/os/file_purge/log | ログファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 92 | 97 | /disk1/job/os/scripts | (監査ログ取得処理用)メインプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 93 | 98 | /disk1/job/os/result | (監査ログ取得処理用)サブプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 94 | 99 | /disk1/job/os/result/apache | apache監査ログ格納ディレクトリ | root | root | 755 | 未実施 |  |
| 95 | 100 | /disk1/job/os/result/ftp | ftp監査ログ格納ディレクトリ | root | root | 755 | 未実施 |  |
| 96 | 101 | /disk1/job/os/result/iptables | iptables監査ログ格納ディレクトリ | root | root | 755 | 未実施 |  |
| 97 | 102 | /disk1/job/os/result/oracle | oracle監査ログ格納ディレクトリ | root | root | 755 | 未実施 |  |
| 98 | 103 | /disk1/job/os/result/ssh | ssh監査ログ格納ディレクトリ | root | root | 755 | 未実施 |  |
| 99 | 104 | /disk1/job/os/result/weblogic_01 | weblogic_01監査ログ格納ディレクトリ | root | root | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 100 | 105 | /disk1/job/os/result/weblogic_02 | weblogic_02監査ログ格納ディレクトリ | root | root | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 101 | 106 | /disk1/job/os/tmp | (監査ログ取得処理用)一時ファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 102 | 107 | /disk1/job/os/conf | (監査ログ取得処理用)対象ファイルリスト格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 103 | 108 | /disk1/job/os/log | (監査ログ取得処理用)ログファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 104 | 109 | /disk1/job/comn | 共通PFバックアッププログラム格納ディレクトリ | cpbackup | cpbackup | 755 | 未実施 |  |
| 105 | 110 | /disk1/job/comn/backup | 共通PFバックアップ/ミラーリング処理用ディレクトリ | cpbackup | cpbackup | 755 | 未実施 |  |
| 106 | 111 | /disk1/job/comn/backup/scripts | メインプログラム格納ディレクトリ | cpbackup | cpbackup | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 107 | 112 | /disk1/job/comn/backup/sub | サブプログラム格納ディレクトリ | cpbackup | cpbackup | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 108 | 113 | /disk1/job/comn/backup/sql | SQLプログラム格納ディレクトリ | cpbackup | cpbackup | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 109 | 114 | /disk1/job/comn/backup/out | アウトプットファイル格納ディレクトリ | cpbackup | cpbackup | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 110 | 115 | /disk1/job/comn/backup/tmp | 一時ファイル格納ディレクトリ | cpbackup | cpbackup | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 111 | 116 | /disk1/job/comn/backup/log | ログファイル格納ディレクトリ | cpbackup | cpbackup | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 112 | 117 | /disk1/job/weblogic | Weblogic起動・停止処理用ディレクトリ | root | root | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 113 | 118 | /disk1/job/weblogic/scripts | メインプログラム格納ディレクトリ | root | root | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 114 | 119 | /disk1/job/weblogic/sub | サブプログラム格納ディレクトリ | root | root | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 115 | 120 | /disk1/job/weblogic/sql | SQLプログラム格納ディレクトリ | root | root | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 116 | 121 | /disk1/job/weblogic/out | アウトプットファイル格納ディレクトリ | root | root | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 117 | 122 | /disk1/job/weblogic/tmp | 一時ファイル格納ディレクトリ | root | root | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 118 | 123 | /disk1/job/weblogic/log | ログファイル格納ディレクトリ | root | root | 777 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 119 | 124 | /disk1/job/apache | Apache起動・停止処理用ディレクトリ | root | root | 755 | 未実施 |  |
| 120 | 125 | /disk1/job/apache/scripts | メインプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 121 | 126 | /disk1/job/apache/sub | サブプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 122 | 127 | /disk1/job/apache/sql | SQLプログラム格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 123 | 128 | /disk1/job/apache/out | アウトプットファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 124 | 129 | /disk1/job/apache/tmp | 一時ファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 125 | 130 | /disk1/job/apache/log | ログファイル格納ディレクトリ | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 126 | 131 | /disk2 | （記載なし）【要確認】 | root | root | 755 | 未実施 | マウントポイント（ディスク構成手順でマウント済みであること。findmnt で確認） |
| 127 | 132 | /disk2/purge | ファイルパージ処理退避圧縮ファイル格納ディレクトリ (※[統合顧客DB-機能設計書(ファイルパージ処理)]を参照) | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 128 | 133 | /opt | Weblogicインストールディレクトリ (※[統合顧客DBシステム WebLogic設計書]を参照) | root | root | 755 | 未実施 | OS 標準で存在（既存として報告される） |
| 129 | 134 | /opt/oracle | （記載なし）【要確認】 | weblogic | oinstall | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 130 | 135 | /opt/oracle/middleware | （記載なし）【要確認】 | weblogic | oinstall | 750 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 131 | 136 | /opt/oracle/middleware/wlserver_10.3 | （記載なし）【要確認】 | weblogic | oinstall | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない） |
| 132 | 137 | /home | （記載なし）【要確認】 | root | root | 755 | 未実施 | OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示） |
| 133 | 138 | /home/weblogic | （記載なし）【要確認】 | weblogic | oinstall | 700 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；ホームは useradd -m（ユーザ・グループ手順）で作成済みのはず。未作成なら本スクリプトが作成する |
| 134 | 139 | /home/weblogic/add_on | リリース作業用 | weblogic | oinstall | 755 | 未実施 | WebLogic 専用のため Tomcat では不要・読み替えの可能性【要確認】（推測で削除・変更しない）；ホームは useradd -m（ユーザ・グループ手順）で作成済みのはず。未作成なら本スクリプトが作成する |
| 135 | 140 | /work | （記載なし）【要確認】 | root | root | 755 | 未実施 |  |
| 136 | 141 | /work/OS | （記載なし）【要確認】 | root | root | 777 | 未実施 | 777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 137 | 142 | /work/OS/iptables | iptables設定作業用ディレクトリ | root | root | 777 | 未実施 | RHEL 8 は firewalld のため用途の継続要否【要確認】；777 は定義書の値をそのまま使用（セキュリティ強化の観点での見直しは【要確認】） |
| 138 | 143 | /usr | （記載なし）【要確認】 | root | root | 755 | 未実施 | OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示） |
| 139 | 144 | /usr/local | （記載なし）【要確認】 | root | root | 755 | 未実施 | OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示） |
| 140 | 145 | /usr/local/bin | aws cliコマンド(symlink)格納ディレクトリ | root | root | 755 | 未実施 | OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示） |
| 141 | 146 | /usr/local/lib | （記載なし）【要確認】 | root | root | 755 | 未実施 | OS 標準で存在（既存として報告される。定義と権限が異なれば差異を表示） |
| 142 | 147 | /usr/local/lib/aws | aws cliパッケージインストール先 | root | root | 755 | 未実施 | AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】 |
| 143 | 148 | /usr/local/lib/aws/bin | （記載なし）【要確認】 | root | root | 755 | 未実施 | AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】 |
| 144 | 149 | /usr/local/lib/aws/include | （記載なし）【要確認】 | root | root | 755 | 未実施 | AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】 |
| 145 | 150 | /usr/local/lib/aws/lib | （記載なし）【要確認】 | root | root | 755 | 未実施 | AWS CLI v2 のインストーラが作成するディレクトリ。先に本スクリプトで作成しても支障はないが順序は【要確認】 |
