# frozen_string_literal: true

module Box
  module Helpers
    module ErrorHandler
      def log_error(exception, logger_prefix: "generic")
        Sentry.capture_exception(exception) if ENV["SENTRY_DSN"]
        Rollbar.error(exception) if ENV["ROLLBAR_ACCESS_TOKEN"]
        Box.logger.error("[#{logger_prefix}] #{exception.class} :: \"#{exception.message}\"")
      end
    end
  end
end
