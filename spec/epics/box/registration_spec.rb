require_relative '../../spec_helper'
require_relative '../../../lib/epics/box/registration'

module Epics
  module Box
    RSpec.describe Registration do
      context 'invalid data' do
        it 'returns a bad request response' do
          post '/organizations'
          expect_status 400
        end

        it 'includes a meaningful error message' do
          post '/organizations'
          expect_json 'message', "Validation of your request's payload failed!"
        end

        it 'includes missing fields' do
          post '/organizations'
          expect_json 'errors', { name: ["is missing"] }
        end
      end

      context 'valid data without preset management token' do
        it 'returns a OK response' do
          post '/organizations', { name: "New Organization" }
          expect_status 201
        end

        it 'generates a management token' do
          post '/organizations', { name: "New Organization" }
          expect(Organization.last.management_token).to_not be_nil
        end

        it 'includes a generated management token in its response' do
          post '/organizations', { name: "New Organization" }
          expect_json 'management_token', Organization.last.management_token
        end
      end

      context 'valid data with preset management token' do
        it 'returns a OK response' do
          post '/organizations', { name: "New Organization", management_token: 'some-token' }
          expect_status 201
        end

        it 'stores the preset management token' do
          post '/organizations', { name: "New Organization", management_token: 'some-token' }
          expect(Organization.last.management_token).to eq('some-token')
        end

        it 'includes the preset management token in its response' do
          post '/organizations', { name: "New Organization", management_token: 'some-token' }
          expect_json 'management_token', 'some-token'
        end
      end
    end
  end
end
