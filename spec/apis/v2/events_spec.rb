# frozen_string_literal: true

require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Events do
    include_context 'valid user'
    include_context 'with account'

    let!(:event) { account.add_event(type: 'test') }
    let!(:webhook_delivery) { event.add_webhook_delivery({}) }

    describe 'GET /events' do
      context 'without valid access_token' do
        it 'returns a 401' do
          get 'events', TestHelpers::INVALID_TOKEN_HEADER
          expect_status 401
        end
      end

      context 'with valid access_token' do
        it 'returns an OK status' do
          get 'events', TestHelpers::VALID_HEADERS
          expect_status 200
        end

        it 'returns a list of events' do
          get 'events', TestHelpers::VALID_HEADERS
          expect_json_types :array
        end

        it 'exposes each events public id' do
          get 'events', TestHelpers::VALID_HEADERS
          expect_json '0.id', event.public_id
        end

        it 'references the endpoint to fetch more details' do
          get 'events', TestHelpers::VALID_HEADERS
          expect_json '0._links.self', regex(%r{http://localhost:5000/events/#{TestHelpers::UUID_REGEXP}})
        end
      end
    end

    describe 'GET /events/:id' do
      context 'without valid access_token' do
        it 'returns a 401' do
          get "events/#{event.public_id}"
          expect_status 401
        end
      end

      context 'with valid access_token' do
        it 'returns an OK status' do
          get "events/#{event.public_id}", TestHelpers::VALID_HEADERS
          expect_status 200
        end

        it 'exposes each events public id' do
          get "events/#{event.public_id}", TestHelpers::VALID_HEADERS
          expect_json 'id', event.public_id
        end

        it 'includes a list of all webhook delivery attempts' do
          get "events/#{event.public_id}", TestHelpers::VALID_HEADERS
          expect_json_types webhook_deliveries: :array
        end

        it 'includes public_id for payloads' do
          event.payload = { 'public_id': 'asdf', 'whatever': 'payload' }
          event.save
          get "events/#{event.public_id}", TestHelpers::VALID_HEADERS
          expect_json 'payload.public_id', 'asdf'
          expect_json_types 'payload.public_id', :string
          expect_json 'payload.whatever', 'payload'
        end
      end
    end
  end
end
