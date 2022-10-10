-- DB作成
CREATE DATABASE rainbow_database; 

-- 作成したDBへ切り替え
\c rainbow_database

-- スキーマ作成
CREATE SCHEMA hogeschema;

-- ロールの作成
CREATE ROLE hoge WITH LOGIN PASSWORD 'passw0rd';

-- 権限追加
GRANT ALL PRIVILEGES ON SCHEMA hogeschema TO hoge;
