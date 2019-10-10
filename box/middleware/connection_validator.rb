# frozen_string_literal: true

module Box
  module Middleware
    class ConnectionValidator
      def initialize(app, db)
        @app = app
        @db  = db

        @db.extension(:connection_validator)
        @db.pool.connection_validation_timeout = -1
      end

      def call(env)
        @db.synchronize do
          @app.call(env)
        end
      end
    end
  end
end
