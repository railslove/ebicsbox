# frozen_string_literal: true

require 'faraday'

module Box
  module Middleware
    class Signer < Faraday::Middleware
      SIGNATURE_HEADER = 'X-Signature'

      def initialize(app, opts = {})
        super(app)
        @opts = opts
      end

      def call(env)
        env.request_headers[SIGNATURE_HEADER] ||= sign(env.request_body).to_s if secret
        @app.call(env)
      end

      private

      def sign(msg)
        'sha1=' + OpenSSL::HMAC.hexdigest(digest, secret, msg.to_s)
      end

      def digest
        OpenSSL::Digest.new('sha1')
      end

      def secret
        @opts[:secret]
      end
    end
  end
end

Faraday::Request.register_middleware signer: -> { Box::Middleware::Signer }
