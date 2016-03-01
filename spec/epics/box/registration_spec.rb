require_relative '../../spec_helper'
require_relative '../../../lib/epics/box/registration'
require_relative '../../../lib/epics/box/configuration'

module Epics
  module Box
    RSpec.describe Registration do
      context 'registrations disabled' do
        before { allow_any_instance_of(Configuration).to receive(:registrations_allowed?).and_return(false) }

        it 'returns a method not allowed error' do
          post '/organizations'
          expect_status 405
        end

        it 'includes a meaningful error message' do
          post '/organizations'
          expect_json 'message', "Registration is not enabled. Please contact an admin!"
        end
      end

      context 'registrations allowed' do
        before { allow_any_instance_of(Configuration).to receive(:registrations_allowed?).and_return(true) }

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
            post '/organizations', { name: "New Organization", user: { name: "John Doe" } }
            expect_status 201
          end

          it 'generates a user access token' do
            post '/organizations', { name: "New Organization", user: { name: "John Doe" } }
            expect(User.last.access_token).to_not be_nil
          end

          it 'includes the generated user access token in its response' do
            post '/organizations', { name: "New Organization", user: { name: "John Doe" } }
            expect_json 'user.access_token', User.last.access_token
          end
        end

        context 'valid data with preset management token' do
          it 'returns a OK response' do
            post '/organizations', { name: "New Organization", user: { name: "John Doe", access_token: 'some-token' } }
            expect_status 201
          end

          it 'stores the preset management token' do
            post '/organizations', { name: "New Organization", user: { name: "John Doe", access_token: 'some-token' } }
            expect(User.last.access_token).to eq('some-token')
          end

          it 'includes the preset management token in its response' do
            post '/organizations', { name: "New Organization", user: { name: "John Doe", access_token: 'some-token' } }
            expect_json 'user.access_token', 'some-token'
          end
        end

      end
    end
  end
end
