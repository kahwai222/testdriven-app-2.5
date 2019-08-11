#!/bin/bash


type=$1
fails=""

inspect() {
  if [ $1 -ne 0 ]; then
    fails="${fails} $2"
  fi
}

# run server-side tests
server() {
  docker-compose up -d --build
  winpty docker-compose exec users python manage.py test
  inspect $? users
  winpty docker-compose exec users flake8 project
  inspect $? users-lint
  docker-compose down
}

# run client-side tests
client() {
  docker-compose up -d --build
  winpty docker-compose exec client npm test -- --coverage
  inspect $? client
  docker-compose down
}

# run e2e tests
e2e() {
  docker-compose -f docker-compose-prod.yml up -d --build
  sleep 2
  winpty docker-compose -f docker-compose-prod.yml exec users python manage.py recreate_db
  ./node_modules/.bin/cypress run --config baseUrl=http://localhost
  # ./node_modules/.bin/cypress run --config baseUrl=http://192.168.99.100  # on Docker Toolbox
  inspect $? e2e
  docker-compose -f docker-compose-prod.yml down
}

# run all tests
all() {
  docker-compose up -d --build
  winpty docker-compose exec users python manage.py test
  inspect $? users
  winpty docker-compose exec users flake8 project
  inspect $? users-lint
  winpty docker-compose exec client npm run coverage
  inspect $? client
  docker-compose down
  e2e
}

# run appropriate tests
if [[ "${type}" == "server" ]]; then
  echo "Running server-side tests!"
  server
elif [[ "${type}" == "client" ]]; then
  echo "Running client-side tests!"
  client
elif [[ "${type}" == "e2e" ]]; then
  echo "Running e2e tests!"
  e2e
else
  echo "Running all tests!"
  all
fi

# return proper code
if [ -n "${fails}" ]; then
  echo "Tests failed: ${fails}"
  exit 1
else
  echo "Tests passed!"
  exit 0
fi
