module Box
  module Middleware
    class LicenseValidator
      def initialize(app)
        @app = app
      end

      def call(env)
        if license_expired?
          [402, {'Content-Type' => env["HTTP_ACCEPT"], "Content-Length" => "0", "X-Ebics-Box-License-Valid" => "false"}, []]
        else
          @app.call(env)
        end
      end

      private

      def license_expired?
        if license["expiration_time"]
          DateTime.parse(license["expiration_time"]) < DateTime.now
        else
          false
        end
      end

      def license
        HTTParty.get("#{ENV['REPLICATED_INTEGRATIONAPI']}/license/v1/license", verify: false).parsed_response
      rescue
        {}
      end

    end
  end
end
