#!/bin/bash

cp conf/start/zentral/base.json conf/start/zentral/base.json.bak

TLSSECRET=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
DJANGOSECRET=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sed -i "s/API\ SECRET\ \!\!\!\ CHANGE\ THIS\ \!\!\!\ DO\ NOT\ USE\ IN\ PRODUCTION\ \!\!\!/zentral/$TLSSECRET/g" conf/start/zentral/base.json
sed -i "s/DJANGO\ SECRET\ \!\!\!\ CHANGE\ THIS\ \!\!\!\ DO\ NOT\ USE\ IN\ PRODUCTION\ \!\!\!/zentral/$DJANGOSECRET/g" conf/start/zentral/base.json

echo "FQDN for Zentral server:"
read FQDN
sed -i "s/https:\/\/zentral/https:\/\/$FQDN/g" conf/start/zentral/base.json

echo "Admin email address:"
read ADMINEMAIL
sed -i "s/changethis@example.com/$ADMINEMAIL/g" conf/start/zentral/base.json

echo "Basic auth username:"
read BAUSERNAME
echo "Basic auth password:"
read BAPASSWORD
mv conf/basic_auth/docker/nginx/extra/zentral.htpasswd conf/basic_auth/docker/nginx/extra/zentral.htpasswd.bak
htpasswd -cb conf/basic_auth/docker/nginx/extra/zentral.htpasswd $BAUSERNAME $BAPASSWORD
echo "*.htpasswd" >> .gitignore

echo "Enter the full path to your tls certificate:"
read TLSCERTIFICATE
mv conf/start/docker/tls/zentral.crt conf/start/docker/tls/zentral.crt.bak
cp "$TLSCERTIFICATE" conf/start/docker/tls/zentral.crt
echo "*.crt" >> .gitignore

echo "Path to your tls key:"
read TLSKEY
mv conf/start/docker/tls/zentral.key conf/start/docker/tls/zentral.key.bak
cp "$TLSKEY" conf/start/docker/tls/zentral.key
echo "*.key" >> .gitignore

sed -i "s/runserver/gunicorn/g" docker-compose-basic-auth.yml

echo "DB FQDN:"
read DBFQDN
sed -i "s/db/$DBFQDN/g" docker-compose-basic-auth.yml

echo "DB username:"
read DBUSERNAME
sed -i "s/POSTGRES_USER=zentral/POSTGRES_USER=$DBUSERNAME/g" conf/start/docker/postgres.env

echo "DB password:"
read DBPASSWORD
sed -i "s/POSTGRES_PASSWORD=zentral/POSTGRES_PASSWORD=$DBPASSWORD/g" conf/start/docker/postgres.env
echo "*.env" >> .gitignore

echo "DB name:"
read DBNAME
sed -i "s/POSTGRES_DB=zentral/POSTGRES_DB=$DBNAME/g" conf/start/docker/postgres.env

echo "Reset git cache? y or n"
read ANSWER
if [[ $ANSWER == 'y' ]]; then
  git rm --cached -r .
else
  exit 0
fi
