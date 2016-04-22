FROM yoyostile/railslove-jruby:9.0.5.0
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get update && apt-get install -y git supervisor python-pip
RUN pip install supervisor-stdout

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/ebicsbox
WORKDIR /usr/ebicsbox

RUN echo invokedynamic.all=true >> /usr/ebicsbox/.jrubyrc

ADD Gemfile /usr/ebicsbox/
ADD Gemfile.lock /usr/ebicsbox/
RUN bundle install

ADD . /usr/ebicsbox
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#RUN rake jruby:build

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

CMD ["/usr/bin/supervisord"]
