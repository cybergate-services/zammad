#!/usr/bin/env bash
rm -rf ./.env

PASSWORD=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c 28)

cat env ./.env
sed -ie "s/CHANGE_ME/${PASSWORD}/g" ./.env


