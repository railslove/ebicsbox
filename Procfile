web: bundle exec rackup -p $PORT
worker: ruby -I'lib' -r 'epics/http' -e Epics::Http::Worker.new.process!
clock:  clockwork lib/epics/scheduler/scheduler.rb