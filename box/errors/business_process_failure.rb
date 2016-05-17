module Epics
  module Box
    class BusinessProcessFailure < RuntimeError
      attr_accessor :errors

      def initialize(errors, msg = nil)
        super(msg || errors.full_messages.join(" "))
        self.errors = errors
      end
    end
  end
end
