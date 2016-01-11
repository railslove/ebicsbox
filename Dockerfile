FROM jruby:9.0.4.0-jdk
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/ebicsbox
WORKDIR /usr/ebicsbox

RUN echo invokedynamic.all=true >> /usr/ebicsbox/.jrubyrc

ADD Gemfile /usr/ebicsbox/
ADD Gemfile.lock /usr/ebicsbox/
RUN bundle install

RUN npm install webpack -g

ADD . /usr/ebicsbox
RUN npm install
RUN webpack -p
RUN rake jruby:build

RUN rm Dockerfile* > /dev/nul 2>&1
RUN rm Rakefile > /dev/nul 2>&1
RUN rm .env > /dev/nul 2>&1
RUN rm -rf ./node_modules > /dev/nul 2>&1
RUN rm -rf .git > /dev/nul 2>&1
RUN rm -rf pkg > /dev/nul 2>&1
RUN rm -rf log > /dev/nul 2>&1
RUN rm Procfile* > /dev/nul 2>&1
RUN rm README* > /dev/nul 2>&1
RUN rm package.json > /dev/nul 2>&1
RUN rm webpack.config.js > /dev/nul 2>&1

CMD ["bin/start", "server"]
