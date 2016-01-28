$stdout.sync = true

require_relative './queue'

module Box
  class Worker
    def initialize
      @queue ||= Queue.new
    end

    def process!
      @queue.process!
    end
  end
end
