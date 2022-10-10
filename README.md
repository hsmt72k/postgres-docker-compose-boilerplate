# PostgreSQL コンテナのボイラープレート

## 開発環境

- Windows 11 Home ver. 21H2
- Docker Desktop for Windows

## リポジトリのディレクトリ構成

 ``` txt
│  .gitignore
│  db.env.example
│  docker-compose.yml
│  
└─postgresql
    │  Dockerfile
    │  postgresql.conf
    │  
    └─init
        01_initialize.sql
        02_create_table.sql
```

## 各ファイルの説明

### Dockerfile

DockerHub の postgres イメージを利用する。バージョンは 14.0 で、軽量な Alpine を指定する。

`postgres/Dockerfile`
``` Dockerfile
FROM postgres:14.0-alpine
ENV LANG ja_JP.utf8
```

### docker-compose.yml

Dockerfile をビルドする。

ポートは、localhost:15432 に接続されるようにする。

ユーザ名、パスワードなどの環境変数は、`db.env` ファイルから読み込むようにする。

コンテナを停止した後も、DB のデータが永続化されるように、
PostgreSQL コンテナの `data` ディレクトリをローカルの `db-data` にマウントする。

初期化 SQL エントリーポイントである、`docker-entrypoint-initdb.d` を、
ローカルの `postgres/init` ディレクトリにマウントする。

今回、カレントディレクトリを PostgreSQL のデフォルトスキーマである `public` ではなく、
専用のスキーマを作成するため、専用のスキーマを `postgresql.conf` ファイルに記載して、
設定に反映されるようにしたいため、 `postgresql.conf` もマウントする。 

`docker-compose.yml`
``` yaml
version: '3'
services:
  db:
    container_name: postgresql
    build: ./postgres
    command: -c 'config_file=/etc/postgresql/postgresql.conf'
    ports:
      - 15432:5432
    env_file:
      - db.env
    volumes:
      - ./db-data:/var/lib/postgresql/data
      - ./postgres/init:/docker-entrypoint-initdb.d
      - ./postgres/postgresql.conf:/etc/postgresql/postgresql.conf
```

### db.env

ユーザ名、パスワードの環境変数は、`db.env` ファイルに記載し、
`docker-compose.yml` で読み込むようにする。

`db.env`
``` txt
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
```

ただし、`db.env` にパスワードを記載してリモートリポジトリにコミットしてしまうと、
パスワードがネットワーク上に公開されてしまうため、セキュリティ上、良くない。

そのため、`db.env` ファイルが Git コミットの対象外ファイルとなるように、
`.gitignore` ファイルに `db.env` を記載しておく。

`db.env` への環境変数の記載例は、`db.env.example` を参考にする。

### docker-entrypoint-initdb.d ディレクトリ

PostgreSQL コンテナの `docker-entrypoint-initdb.d` ディレクトリは、特別なディレクトリで、
このディレクトリに配置した SQL ファイルは、コンテナの初回起動時に実行される。

今回は以下の 2 つのファイルを、 `docker-entrypoint-initdb.d` ディレクトリにマウントした
ディレクトリに配置している。

- 01_initialize.sql
- 02_create_table.sql

## コンテナの起動/停止/削除

### コンテナの起動

`docker-compose up` コマンドを `docker-compose.yml` ファイルのディレクトリ内で実行する。

`-d` オプションを付けることでバックグラウンドでコンテナが起動するので、
コンテナ起動後も他のコマンドが打てるようになる。

`コンテナの起動`
``` console
docker-compose up -d
```

### コンテナの停止

コンテナを停止したい場合は、`docker-compose stop` コマンドを実行する。

`コンテナの停止`
``` console
docker-compose stop
```

### コンテナの削除

コンテナを削除したい場合は、`docker-compose down` コマンドを実行する。

`コンテナの削除`
``` console
docker-compose down
```

### コンテナの再起動

コンテナを再起動したい場合は、再び `docker-compose up` コマンドを実行すれば、
DB のデータが前回起動した内容で起動される。

永続化しているデータをクリアしたい場合は、
PostgreSQL コンテナの `data` ディレクトリをマウントしている、
`db-data` ディレクトリを削除した状態でコンテナを起動する。

## コンテナへの接続

ローカルから Docker で立ち上げたコンテナに接続したい場合は、`docker exec` コマンドを実行する。

`
``` console
docker exec -it postgresql /bin/sh
```

## コマンドでの DB 操作（psql）

## DB への接続

PostgreSQL コンテナから、DB に接続するには、`psql` コマンドを実行する。

psql ログイン時には、コンテナ名、ロール名（もしくはユーザ名）、DB名を指定する。

``` console
psql --host={コンテナ名} --username={ロール名 もしくは ユーザ名} -- dbname={DB名}
```

コマンドオプションは、以下のような省略記法を使うこともできる。

``` console
psql -h {コンテナ名} -U {ロール名 もしくは ユーザ名} -d {DB名}
```

## データベース一覧の取得

データベースの一覧を取得するには、psql で `\l` を実行する。

`psql でのデータベース一覧の取得コマンド`
```
\l
```

`実行結果例`
``` console
                                          List of databases
       Name       |    Owner     | Encoding |  Collate   |   Ctype    |       Access privileges
------------------+--------------+----------+------------+------------+-------------------------------
 postgres         | unicorn_user | UTF8     | ja_JP.utf8 | ja_JP.utf8 |
 rainbow_database | unicorn_user | UTF8     | ja_JP.utf8 | ja_JP.utf8 |
 template0        | unicorn_user | UTF8     | ja_JP.utf8 | ja_JP.utf8 | =c/unicorn_user              +
                  |              |          |            |            | unicorn_user=CTc/unicorn_user
 template1        | unicorn_user | UTF8     | ja_JP.utf8 | ja_JP.utf8 | =c/unicorn_user              +
                  |              |          |            |            | unicorn_user=CTc/unicorn_user
 unicorn_user     | unicorn_user | UTF8     | ja_JP.utf8 | ja_JP.utf8 |
(5 rows)
```

## テーブル一覧の取得

テーブルの一覧を取得するには、psql で `\d` を実行する。

`psql でのテーブル一覧の取得コマンド`
```
\d
```

`実行結果例`
``` console
             List of relations
   Schema   |  Name  | Type  |    Owner
------------+--------+-------+--------------
 hogeschema | sample | table | unicorn_user
(1 row)
```

## SQL の実行

psql で SQL を実行して初期セットアップしたデータを確認する。

`SQL`
```
select * from sample;
```

`実行結果例`
``` console
 col1 | col2 | col3
------+------+------
 1111 | 2221 | 3331
 1112 | 2222 | 3332
 1113 | 2223 | 3333
(3 rows)
```

以上。
