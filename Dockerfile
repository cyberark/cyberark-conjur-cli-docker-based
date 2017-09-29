# docker 17.06+ will let us do this:
# ARG RUBY_VERSION=2.2
FROM ruby:${RUBY_VERSION}

RUN mkdir /src
WORKDIR /src

COPY Gemfile Gemfile
COPY conjur-cli.gemspec conjur-cli.gemspec
COPY lib/conjur/version.rb lib/conjur/version.rb

# Make sure only one version of bundler is available
RUN gem uninstall bundler -i /usr/local/lib/ruby/gems/${RUBY_VERSION} bundler || true && \
  gem install bundler -v 1.11.2 || true && \
  bundle install
