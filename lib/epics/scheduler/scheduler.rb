require 'beaneater'
require 'json'

module Clockwork
  BEANEATER = Beaneater::Pool.new(['localhost:11300'])
  handler { |job| BEANEATER.tubes['sta'].put job }

  every(30.seconds, JSON.dump({refresh: "now"}))
end