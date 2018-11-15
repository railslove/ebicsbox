web: bundle exec rackup -p $PORT
beanstalk: beanstalkd
worker: bundle exec sidekiq -C ./config/sidekiq.yml -r ./config/sidekiq.rb
clock: bundle exec clockwork config/scheduler.rb
