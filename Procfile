web: bundle exec rackup -p $PORT
worker: ruby -I'lib' -r 'epics/box' -e Epics::Box::Worker.new.process!
clock:  clockwork lib/epics/scheduler/scheduler.rb