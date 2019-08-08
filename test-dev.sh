#!/bin/bash


fails=""

inspect() {
  if [ $1 -ne 0 ]; then
    fails="${fails} $2"
  fi
}

# run unit and integration tests
docker-compose up -d --build
winpty docker-compose exec users python manage.py test
inspect $? users
winpty docker-compose exec users flake8 project
inspect $? users-lint
winpty docker-compose exec client npm run coverage
inspect $? client
docker-compose down

# run e2e tests
docker-compose -f docker-compose-prod.yml up -d --build
sleep 1
winpty docker-compose -f docker-compose-prod.yml exec users python manage.py recreate_db
./node_modules/.bin/cypress run --config baseUrl=http://localhost
inspect $? e2e
docker-compose -f docker-compose-prod.yml down

## run e2e tests Docker Toolbox
#docker-compose up -d --build
#sleep 1
#winpty docker-compose exec users python manage.py recreate_db
#./node_modules/.bin/cypress run --config baseUrl=http://192.168.99.100
#inspect $? e2e
#docker-compose down

# return proper code
if [ -n "${fails}" ]; then
  echo "Tests failed: ${fails}"
  exit 1
else
  echo "Tests passed!"
  exit 0
fi
