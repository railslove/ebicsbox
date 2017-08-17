require 'faraday'

module Box
  module Middleware
    class Signer < Faraday::Middleware
      SIGNATURE_HEADER = 'X-Signature'.freeze

      def initialize(app, opts = {})
        super(app)
        @opts = opts
      end

      def call(env)
        env[:request_headers][SIGNATURE_HEADER] ||= signature_header(env).to_s if secret
        @app.call(env)
      end

      private

      def signature_header(env)
        'sha1=' + OpenSSL::HMAC.hexdigest(digest, secret, env[:body])
      end

      def digest
        @digest ||= OpenSSL::Digest.new('sha1')
      end

      def secret
        @opts[:secret]
      end
    end
  end
end

Faraday::Request.register_middleware signer: ->{ Box::Middleware::Signer }
