require 'spec_helper'

require_relative '../../box/middleware/static_authentication'

module Box
  module Middleware
    RSpec.describe StaticAuthentication do
      let(:app) { double('App', call: true) }
      let(:middleware) { described_class.new(app) }

      describe 'user authentication' do
        describe 'no access token provided at all' do
          it 'returns no user' do
            env = Rack::MockRequest.env_for('/')
            expect(app).to receive(:call).with(hash_including('box.user' => nil))
            middleware.call(env)
          end

          it 'returns no organization' do
            env = Rack::MockRequest.env_for('/')
            expect(app).to receive(:call).with(hash_including('box.organization' => nil))
            middleware.call(env)
          end
        end

        describe 'invalid access token' do
          it 'returns no user' do
            env = Rack::MockRequest.env_for('/?access_token=test-token')
            expect(app).to receive(:call).with(hash_including('box.user' => nil))
            middleware.call(env)
          end

          it 'returns no organization' do
            env = Rack::MockRequest.env_for('/?access_token=test-token')
            expect(app).to receive(:call).with(hash_including('box.organization' => nil))
            middleware.call(env)
          end
        end

        describe 'authenticated user via query parameter' do
          let!(:organization) { Box::Organization.create(name: "Test Orga") }
          let!(:user) { Box::User.create(name: "Test User", access_token: 'test-token', organization: organization) }

          it 'returns a user' do
            env = Rack::MockRequest.env_for('/?access_token=test-token')
            expect(app).to receive(:call).with(hash_including('box.user' => user))
            middleware.call(env)
          end

          it 'returns an organization' do
            env = Rack::MockRequest.env_for('/?access_token=test-token')
            expect(app).to receive(:call).with(hash_including('box.organization' => organization))
            middleware.call(env)
          end
        end

        describe 'authenticated user via legacy header' do
          let!(:organization) { Box::Organization.create(name: "Test Orga") }
          let!(:user) { Box::User.create(name: "Test User", access_token: 'test-token', organization: organization) }

          it 'returns a user' do
            env = Rack::MockRequest.env_for('/')
            env['HTTP_AUTHORIZATION'] = "token #{user.access_token}"
            expect(app).to receive(:call).with(hash_including('box.user' => user))
            middleware.call(env)
          end

          it 'returns an organization' do
            env = Rack::MockRequest.env_for('/')
            env['HTTP_AUTHORIZATION'] = "token #{user.access_token}"
            expect(app).to receive(:call).with(hash_including('box.organization' => organization))
            middleware.call(env)
          end
        end

        describe 'authenticated user via bearer token header' do
          let!(:organization) { Box::Organization.create(name: "Test Orga") }
          let!(:user) { Box::User.create(name: "Test User", access_token: 'test-token', organization: organization) }

          it 'returns a user' do
            env = Rack::MockRequest.env_for('/')
            env['HTTP_AUTHORIZATION'] = "Bearer #{user.access_token}"
            expect(app).to receive(:call).with(hash_including('box.user' => user))
            middleware.call(env)
          end

          it 'returns an organization' do
            env = Rack::MockRequest.env_for('/')
            env['HTTP_AUTHORIZATION'] = "Bearer #{user.access_token}"
            expect(app).to receive(:call).with(hash_including('box.organization' => organization))
            middleware.call(env)
          end
        end
      end

      describe 'management authentication' do
        skip 'missing implementation'
      end

    end
  end
end
