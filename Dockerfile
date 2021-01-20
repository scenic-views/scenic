FROM ruby:2.7
WORKDIR /app
RUN apt-get install libpq-dev
ADD Gemfile scenic.gemspec ./
ADD lib/scenic/version.rb ./lib/scenic/
RUN bundle install
