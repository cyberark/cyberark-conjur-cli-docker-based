FROM ruby:2.1.5

RUN mkdir /src
WORKDIR /src

COPY Gemfile Gemfile
COPY conjur.gemspec conjur.gemspec
COPY lib/conjur/version.rb lib/conjur/version.rb

RUN bundle install
