FROM ruby:2.5.1-alpine

RUN mkdir /app
WORKDIR /app

RUN apk add --update \
  build-base \
  bash \
  git \
  libxml2-dev \
  libxslt-dev \
  postgresql-dev \
  tzdata \
  && rm -rf /var/cache/apk/*

COPY . .
RUN bundle install
