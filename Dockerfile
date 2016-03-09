FROM ruby:2.2.4

RUN mkdir /src
WORKDIR /src

COPY Gemfile Gemfile
COPY conjur.gemspec conjur.gemspec
COPY lib/conjur/version.rb lib/conjur/version.rb

RUN bundle install
