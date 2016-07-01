require "spec_helper"

require_relative "../../../box/models/event"

module Box
  module Entities
    module V2
      RSpec.describe Event do
        describe "type mapping" do
          it "transforms subscriber to account activation" do
            event = Box::Event.new(type: "subscriber_activated")
            expect(described_class.represent(event).as_json).to match(hash_including(type: "account_activated"))
          end

          it "transforms debit_created to direct_debit_created" do
            event = Box::Event.new(type: "debit_created")
            expect(described_class.represent(event).as_json).to match(hash_including(type: "direct_debit_created"))
          end

          it "transforms credit_created to credit_transfer_created" do
            event = Box::Event.new(type: "credit_created")
            expect(described_class.represent(event).as_json).to match(hash_including(type: "credit_transfer_created"))
          end

          it "transforms statement_created to transaction_created" do
            event = Box::Event.new(type: "statement_created")
            expect(described_class.represent(event).as_json).to match(hash_including(type: "transaction_created"))
          end
        end
      end
    end
  end
end
