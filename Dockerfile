FROM ruby:3.3.2-slim
ARG DOCKER_TAG
ENV APP_VERSION=$DOCKER_TAG

RUN apt-get update && apt-get install -y git supervisor build-essential zlib1g-dev libpq-dev curl

# throw errors if Gemfile has been modified since Gemfile.lock

RUN bundle config --global frozen 1 

RUN mkdir -p /usr/ebicsbox
WORKDIR /usr/ebicsbox

ADD Gemfile /usr/ebicsbox/
ADD Gemfile.lock /usr/ebicsbox/
RUN gem install bundler -v 2.3.22
RUN bundle install

ADD . /usr/ebicsbox
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Clean up
RUN rm -rf pkg

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bin/start", "all"]
HEALTHCHECK --interval=30s --timeout=3s CMD bin/healthchecks/all
