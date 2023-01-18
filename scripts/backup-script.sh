#!/usr/bin/env bash

FILENAME=backupmariadb-$(date +%Y-%m-%d-\%I:\%M:\%S_\%p)

mysqldump openmrs > "/home/deployment/databasebackups/$FILENAME.sql"

sudo gpg --batch --yes --output "/home/deployment/databasebackups/$FILENAME.gpg" --encrypt --recipient blopup.upc.edu@gmail.com "/home/deployment/databasebackups/$FILENAME.sql"

rm "/home/deployment/databasebackups/$FILENAME.sql"

find /home/deployment/databasebackups -ctime +90  -exec rm {} \;
