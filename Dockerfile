FROM jruby:9.0.4.0-jdk

ENV DATABASE_URL=jdbc:postgresql://postgres/postgres?user=postgres
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/ebicsbox
WORKDIR /usr/ebicsbox

RUN echo invokedynamic.all=true >> /usr/ebicsbox/.jrubyrc

ADD Gemfile /usr/ebicsbox/
ADD Gemfile.lock /usr/ebicsbox/
RUN mkdir -p /usr/ebicsbox/vendor/cache
ADD vendor/cache /usr/ebicsbox/vendor/cache
RUN cd /usr/ebicsbox && bundle install --deployment --local --without development test

RUN npm install webpack -g

ADD . /usr/ebicsbox
RUN npm install
RUN webpack -p
RUN rake jruby:build

RUN rm Dockerfile*
RUN rm .env
RUN rm -rf ./node_modules
RUN rm -rf .git
RUN rm -rf pkg
RUN rm -rf log
RUN rm Procfile*
RUN rm README*
RUN rm package.json
RUN rm webpack.config.js

CMD ["bin/start", "server"]
