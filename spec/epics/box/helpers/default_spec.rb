require 'spec_helper'

require 'grape'
require 'lib/epics/box/helpers/default'

module Epics
  module Box
    module Helpers
      RSpec.describe Default do
        include Rack::Test::Methods

        class TestApi < Grape::API
          format :json
          helpers Helpers::Default

          get '/access_token' do
            access_token
          end
        end

        def app
          TestApi
        end

        def json_response
          JSON.parse(last_response.body, quirks_mode: true)
        end

        describe '.access_token' do
          it 'returns nil of no token is provided' do
            get '/access_token'
            expect(json_response).to eq(nil)
          end

          it 'returns the url param access token if provided' do
            get '/access_token?access_token=url-token'
            expect(json_response).to eq('url-token')
          end

          context 'invalid token keyword' do
            it 'returns the header access token if provided' do
              header "Authorization", "token header-token"
              get '/access_token'
              expect(json_response).to eq('header-token')
            end

            it 'returns the url token if both, header and url token, are provided' do
              header "Authorization", "token header-token"
              get '/access_token?access_token=url-token'
              expect(json_response).to eq('url-token')
            end
          end

          context 'proper oauth bearer token keyword' do
            it 'returns the header access token if provided' do
              header "Authorization", "Bearer header-token"
              get '/access_token'
              expect(json_response).to eq('header-token')
            end

            it 'returns the url token if both, header and url token, are provided' do
              header "Authorization", "Bearer header-token"
              get '/access_token?access_token=url-token'
              expect(json_response).to eq('url-token')
            end
          end
        end
      end
    end
  end
end
