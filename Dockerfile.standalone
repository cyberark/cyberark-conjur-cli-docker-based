# This dockerfile builds a standalone CLI container of the possum branch.
# It's intended to work with automated dockerhub builds.
#
# On build, it updates the conjur-api from git to make sure it's up-to-date,
# then installs the CLI system-wide.
#
# Entrypoint is bash, with `conjur` command available.

FROM ruby:2.4.1

# some useful tools for interactive usage
RUN apt-get update && apt-get install -y --no-install-recommends \
  jq curl vim nano \
  && rm -rf /var/lib/apt/lists/*

# cache a reasonable version of api-ruby & deps
RUN mkdir -p /usr/src && \
    cd /usr/src && \
    git clone https://github.com/conjurinc/api-ruby.git -b possum && \
    cd api-ruby && \
    rake install

COPY standalone.entrypoint /bin/entry

# update API and install everything
COPY . /usr/src/cli-ruby

# only reinstall API if changed
RUN cd /usr/src/api-ruby && git fetch && \
    if [ $(git rev-parse HEAD origin/possum | uniq | wc -l) -gt 1 ]; then \
      git reset --hard origin/possum && rake install ; \
    fi

RUN cd /usr/src/cli-ruby && rake install

ENTRYPOINT ["/bin/entry"]
