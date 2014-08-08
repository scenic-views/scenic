#!/usr/bin/env bats

setup() {
  cd spec/dummy
  git init
  git add -A
  git commit --no-gpg-sign --message "initial"
}

teardown() {
  git add -A
  git reset --hard HEAD
  rm -rf .git/
  rake db:drop db:create
}

@test "generate a model and migrate" {
  rails generate scenic:model search
  [[ -f db/views/searches_v01.sql ]]
  [[ -f app/models/searches.rb ]]
  [[ -n "$(find db/migrate -name "*create_searches.rb" -print -quit)" ]]
  echo "select text 'hi' as hello" > db/views/searches_v01.sql

  rake db:migrate
}

@test "use generators to update a view" {
  rails generate scenic:view search
  echo "select text 'hi' as hello" > db/views/searches_v01.sql

  rails generate scenic:view search
  [[ -f db/views/searches_v02.sql ]]
  [[ -n "$(find db/migrate -name "*_update_searches_to_version_2.rb" -print -quit)" ]]
  echo "select text 'bye' as hello" > db/views/searches_v02.sql

  rake db:migrate
}

@test "generators can be reversed with destroy" {
  rails generate scenic:view search
  rails generate scenic:view search

  rails destroy scenic:view search
  [[ ! -f db/views/searches_v02.sql ]]
  [[ -z "$(find db/migrate -maxdepth 1 -name "*update_searches_to_version_2.rb" -print -quit)" ]]
  [[ -f db/views/searches_v01.sql ]]
  [[ -n "$(find db/migrate -name "*create_searches.rb" -print -quit)" ]]

  rails destroy scenic:view search
  [[ ! -f db/views/searches_v01.sql ]]
  [[ -z "$(find db/migrate -maxdepth 1 -name "*create_searches.rb" -print -quit)" ]]
}
