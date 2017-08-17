require 'spec_helper'
require 'faraday/utils'

require_relative '../../box/middleware/signer'

module Box
  module Middleware
    RSpec.describe Signer do
      def perform(params = {}, headers = {}, body = { foo: :bar }.to_json)
        env = {
          url: URI('http://example.com/?' + Faraday::Utils.build_query(params)),
          request_headers: Faraday::Utils::Headers.new.update(headers),
          body: body
        }
        app = make_app
        app.call(Faraday::Env.from(env))
      end

      def make_app
        described_class.new(->(env) { env }, options)
      end

      def signature_header(env)
        env[:request_headers]['X-Signature']
      end

      context 'hmac calculation' do
        let(:options) { { secret: 'mysecret' } }

        it 'calculates hmac for body' do
          expect(signature_header(perform)).to eq('sha1=d03207e4b030cf234e3447bac4d93add4c6643d8')
        end

        it 'sha changes with different bodies' do
          expect(signature_header(perform({}, {}, { drink: :beer }.to_json))).to eq('sha1=6cd7bbe94a84c32c7aa9bfa48b7187ffc238b248')
        end

        it 'doesn\'t crash with nil value' do
          expect(signature_header(perform({}, {}, nil))).to eq('sha1=33f9d709782f62b8b4a0178586c65ab098a39fe2')
        end
      end
    end
  end
end
