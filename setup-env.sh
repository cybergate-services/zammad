#!/usr/bin/env bash
rm -rf ./.env

PASSWORD=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c 28)

ZAMMAD_DB_PASSWORD
