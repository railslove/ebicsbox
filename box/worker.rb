$stdout.sync = true

module Epics
  module Box
    class Worker
      def initialize
        @queue ||= Box::Queue.new
      end

      def process!
        @queue.process!
      end
    end
  end
end
