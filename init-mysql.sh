#!/usr/bin/env bash
# Creates the MySQL database of Blog when the image is built (see /infrastructure/api/restgym-mysql.sh)

source /infrastructure/api/restgym-mysql.sh

restgym_mysql_init <<SQL
CREATE DATABASE blogapi;
CREATE USER blog@localhost IDENTIFIED BY 'blog';
GRANT ALL PRIVILEGES ON blogapi.* TO blog@localhost;
USE blogapi;
SOURCE /api/database/blogapi.sql;
SQL
