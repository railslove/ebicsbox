FROM yoyostile/jruby:9.0.5.0
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs git

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
#RUN rake jruby:build

# Generate documentation
RUN sed -i.bak 's/localhost:80/ebics-box-test\.apps\.railslabs\.com:443/g' doc/swagger/swagger.json

# Clean up
RUN rm Dockerfile*
RUN rm Rakefile
RUN rm -rf ./node_modules
RUN rm -rf .git
RUN rm -rf pkg
RUN rm -rf log
RUN rm Procfile*
RUN rm README*
RUN rm package.json
RUN rm webpack.config.js
RUN rm docker-compose.yml
RUN rm replicated-compose.yml

CMD ["bin/start", "all"]
