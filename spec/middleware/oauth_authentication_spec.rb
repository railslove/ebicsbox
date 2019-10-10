# frozen_string_literal: true

require 'spec_helper'
require 'jwt'

require_relative '../../box/middleware/oauth_authentication'

module Box
  module Middleware
    RSpec.describe OauthAuthentication do
      let(:app) { double('App', call: true) }
      let(:middleware) { described_class.new(app) }
      let(:token) { JWT.encode(token_payload, Box.configuration.jwt_secret, 'HS512') }

      before do
        allow(Box.configuration).to receive(:jwt_secret) { 'test-secret' }
        WebMock.stub_request(:head, 'http://localhost:3000/oauth/token/info').to_return(status: 200)
      end

      def generate_token(user, organization, role: '')
        {
          jti: SecureRandom.uuid,
          sub: user.id,
          name: user.name,
          organization: {
            sub: organization.id,
            name: organization.name
          },
          verified: false,
          ebicsbox: { role: role }
        }
      end

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
            env = Rack::MockRequest.env_for('/?access_token=invalid-token')
            expect(app).to receive(:call).with(hash_including('box.user' => nil))
            middleware.call(env)
          end

          it 'returns no organization' do
            env = Rack::MockRequest.env_for('/?access_token=invalid-token')
            expect(app).to receive(:call).with(hash_including('box.organization' => nil))
            middleware.call(env)
          end
        end

        context 'existing organization and user' do
          let!(:organization) { Fabricate(:organization) }
          let!(:user) { Box::User.create(id: 1, name: 'Test User', organization: organization) }
          let(:token_payload) { generate_token(user, organization) }

          describe 'authenticated user via query parameter' do
            it 'returns a user' do
              env = Rack::MockRequest.env_for("/?access_token=#{token}")
              expect(app).to receive(:call).with(hash_including('box.user' => user))
              middleware.call(env)
            end

            it 'returns an organization' do
              env = Rack::MockRequest.env_for("/?access_token=#{token}")
              expect(app).to receive(:call).with(hash_including('box.organization' => organization))
              middleware.call(env)
            end
          end

          describe 'authenticated user via bearer token header' do
            it 'returns a user' do
              env = Rack::MockRequest.env_for('/')
              env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
              expect(app).to receive(:call).with(hash_including('box.user' => user))
              middleware.call(env)
            end

            it 'returns an organization' do
              env = Rack::MockRequest.env_for('/')
              env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
              expect(app).to receive(:call).with(hash_including('box.organization' => organization))
              middleware.call(env)
            end
          end
        end

        context 'existing organization but user is new' do
          let!(:organization) { Fabricate(:organization) }
          let!(:user) { double(id: 2, name: 'New user') }
          let(:token_payload) { generate_token(user, organization) }

          it 'returns the existing organization' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.organization' => organization))
            middleware.call(env)
          end

          it 'returns a user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.user' => instance_of(User)))
            middleware.call(env)
          end

          it 'creates a new user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect { middleware.call(env) }.to change { User.count }.by(1)
          end

          it 'sets correct properties on user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            middleware.call(env)
            expect(User.last).to have_attributes(id: 2, name: 'New user', organization_id: organization.id)
          end
        end

        context 'neither organization nor user exist' do
          let!(:organization) { double(id: 2, name: 'New orga') }
          let!(:user) { double(id: 2, name: 'New user') }
          let(:token_payload) { generate_token(user, organization) }

          it 'returns an organization' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.organization' => instance_of(Organization)))
            middleware.call(env)
          end

          it 'creates a new organization' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect { middleware.call(env) }.to change { Organization.count }.by(1)
          end

          it 'sets correct properties on organization' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            middleware.call(env)
            expect(Organization.last).to have_attributes(id: 2, name: 'New orga')
          end

          it 'returns a user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.user' => instance_of(User)))
            middleware.call(env)
          end

          it 'creates a new user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect { middleware.call(env) }.to change { User.count }.by(1)
          end

          it 'sets correct properties on user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            middleware.call(env)
            expect(User.last).to have_attributes(id: 2, name: 'New user', organization_id: organization.id)
          end
        end
      end

      describe 'admin permissions' do
        let!(:organization) { double(id: 3, name: 'New orga') }
        let!(:user) { double(id: 3, name: 'New user') }

        context 'user does not have any role' do
          let(:token_payload) { generate_token(user, organization, role: '') }

          it 'set sets admin flag to false' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.admin' => false))
            middleware.call(env)
          end
        end

        context 'user has admin role' do
          let(:token_payload) { generate_token(user, organization, role: 'admin') }

          it 'set sets admin flag to true' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.admin' => true))
            middleware.call(env)
          end
        end
      end

      describe 'token validation' do
        let!(:organization) { double(id: 3, name: 'New orga') }
        let!(:user) { double(id: 3, name: 'New user') }

        context 'revoked token' do
          let(:token_payload) { generate_token(user, organization) }

          before do
            WebMock.stub_request(:head, 'http://localhost:3000/oauth/token/info').to_return(status: 401)
          end

          it 'sets no user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.user' => nil))
            middleware.call(env)
          end
        end

        context 'valid token' do
          let(:token_payload) { generate_token(user, organization) }

          before do
            WebMock.stub_request(:head, 'http://localhost:3000/oauth/token/info').to_return(status: 200)
          end

          it 'sets a user' do
            env = Rack::MockRequest.env_for("/?access_token=#{token}")
            expect(app).to receive(:call).with(hash_including('box.user' => instance_of(User)))
            middleware.call(env)
          end
        end
      end
    end
  end
end
