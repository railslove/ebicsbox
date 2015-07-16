FROM jruby:1.7-jdk

RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/ebicsbox
WORKDIR /usr/ebicsbox

RUN echo compat.version=2.0 > /usr/ebicsbox/.jrubyrc
RUN echo invokedynamic.all=true >> /usr/ebicsbox/.jrubyrc

ADD epics-box.gemspec /usr/ebicsbox/
ADD lib/epics/box/version.rb /usr/ebicsbox/lib/epics/box/version.rb
ADD Gemfile /usr/ebicsbox/
ADD Gemfile.lock /usr/ebicsbox/
RUN bundle install

RUN npm install webpack -g

ADD . /usr/ebicsbox
RUN npm install
RUN webpack -p

RUN rm Dockerfile*
RUN rm Rakefile
RUN rm .env
RUN rm -rf .node_modules
RUN rm -rf .git
RUN rm -rf pkg

CMD ["bin/start", "server"]
