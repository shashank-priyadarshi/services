#!/bin/bash

# Check if at least one argument is received
if [ $# -lt 1 ]; then
  echo "Error: GitHub token is required."
  exit 1
fi

# Set the value of GITHUB_TOKEN
GITHUB_TOKEN=$1
DEV_SETUP=0
BRANCH_NAME=dev

# Check if two arguments are received
if [ $# -eq 2 ]; then
  # Set the value of DEV_SETUP
  DEV_SETUP=$2
  BRANCH_NAME=main
fi

echo "Running setup in $(if [[ $DEV_SETUP -eq 0 ]]; then echo development; else echo production; fi) mode"

gclone() {
  git clone -b $1 $2
}
GITHUB_URL=https://github.com/shashank-priyadarshi

# Check if local installations of git, node, npm and golang are available
# Check if Git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Please install Git and try again."
  echo "You can install Git by running the following command: apt-get install git"
  exit 1
fi

# Check if Node is installed
if ! command -v node &> /dev/null; then
  echo "Node is not installed. Please install Node and try again."
  echo "You can install Node by running the following command: apt-get install nodejs"
  exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "npm is not installed. Please install npm and try again."
  echo "You can install npm by running the following command: apt-get install npm"
  exit 1
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
  echo "Go is not installed. Please install Go and try again."
  echo "You can install Go by running the following command: apt-get install golang"
  exit 1
fi

# Check Go version
go_version=$(go version | awk -F '[ .]' '{print $3 $4}' | sed 's/go//')
#go_version=$(go version | awk -F '[ .]' '{print $3 $4}')
#go_version=${go_version//go/}
if [[ $go_version -lt 120 ]]; then
  echo "Go version must be greater than or equal to 1.20. Current version: $(go version)"
  exit 1
fi

mkdir -p ~/Code && mkdir -p ~/mongodb/data && cd ~/Code || exit 1
gclone $BRANCH_NAME $GITHUB_URL/services
cp -r ~/Code/services/portfolio/* ~/mongodb/ && cd ~/mongodb/
COLLECTIONS="\"$GITHUB\", \"$GRAPH\", \"$SCHEDULE\""
sed -i 's/^const dbName=.*/const dbName="'"$MONGO_INITDB_DATABASE"'";/' init-mongo.js
sed -i 's/^const collections=.*/const collections= ['"$COLLECTIONS"'];/' init-mongo.js
#sed -i "s/^const dbName=.*/const dbName=\"$DB_NAME\";/" init-mongo.js
#sed -i "s/^const collections=.*/const collections= [$COLLECTIONS];/" init-mongo.js
sed -i.bak -e "s|('adminpass123', 'salt')|('$ADMIN_PASSWORD', '$ADMIN_SALT')|" \
           -e "s|('Admin', 'admin@example.com', 'admin',|('$ADMIN', '$ADMIN_EMAIL', '$ADMIN_USERNAME',|" init.sql
rm init.sql.bak
export MONGO_URI="mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@localhost:27017/${MONGO_INITDB_DATABASE}"
export SQL_URI="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@mysql:3306/${MYSQL_DATABASE}"

# Write a script that starts prerequisite containers for backend, then initialises mongo and sql instances with default values
docker-compose up -d || exit 1


# Backlog: Write a script that picks docker-compose from services repo and builds code, then starts containers
#gclone $BRANCH_NAME $GITHUB_URL/portfolio && gclone $BRANCH_NAME $GITHUB_URL/upgraded-disco
#cd upgraded-disco && go mod tidy && go get -u && git commit -am "updated dep packages" && export GH=$GITHUB_TOKEN && export SETUP=$DEV_SETUP && gnome-terminal -- bash -c "air; if [ \$? -ne 0 ]; then exit; fi"
#cd ../portfolio && npm i --f --legacy-peer-deps && gnome-terminal -- bash -c "npm run start; if [ \$? -ne 0 ]; then exit; fi"
