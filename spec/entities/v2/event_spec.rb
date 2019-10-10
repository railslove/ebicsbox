# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../box/models/event'

module Box
  module Entities
    module V2
      RSpec.describe Event do
        describe 'type mapping' do
          it 'transforms ebics_user to account activation' do
            event = Box::Event.new(type: 'ebics_user_activated')
            expect(described_class.represent(event).as_json).to match(hash_including(type: 'account_activated'))
          end

          it 'does not transforms debit_created' do
            event = Box::Event.new(type: 'debit_created')
            expect(described_class.represent(event).as_json).to match(hash_including(type: 'debit_created'))
          end

          it 'does not transforms credit_created' do
            event = Box::Event.new(type: 'credit_created')
            expect(described_class.represent(event).as_json).to match(hash_including(type: 'credit_created'))
          end

          it 'transforms statement_created to transaction_created' do
            event = Box::Event.new(type: 'statement_created')
            expect(described_class.represent(event).as_json).to match(hash_including(type: 'transaction_created'))
          end
        end
      end
    end
  end
end
