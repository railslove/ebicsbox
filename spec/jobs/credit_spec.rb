# frozen_string_literal: true

require "spec_helper"
require "base64"

module Box
  module Jobs
    RSpec.describe Credit do
      describe "#perform" do
        subject(:job) { described_class.new }
        let(:last_transaction) { Transaction.last }
        let(:message) do
          {
            amount: 100,
            instrument: "CORE",
            eref: "123",
            account_id: 321,
            payload: "PAIN"
          }
        end

        before do
          allow_any_instance_of(Transaction).to receive(:execute!).and_return(true)
          allow(Queue).to receive(:update_processing_status)
          allow(Account).to receive(:[]).and_return(double("account", organization: double("orga", webhook_token: "token")))
        end

        it "creates a transaction" do
          expect { job.perform(message) }.to change { Transaction.count }.by(1)
        end

        it "sets correct order type" do
          job.perform(message)
          expect(last_transaction.type).to eq("credit")
        end

        it "sets correct amount" do
          job.perform(message)
          expect(last_transaction.amount).to eq(100)
        end

        it "encodes the pain payload with base 64" do
          encoded_payload = Base64.strict_decode64("PAIN")
          job.perform(message)
          expect(last_transaction.payload).to eq(encoded_payload)
        end

        it "executes the created transaction" do
          expect_any_instance_of(Transaction).to receive(:execute!)
          job.perform(message)
        end

        it "tells the system to check for job processing status" do
          job.perform(message)
          expect(Queue).to have_received(:update_processing_status).with(321)
        end

        it "logs an info message" do
          expect(Box.logger).to receive(:info).with(/\[Jobs::Credit\] Created credit! transaction_id=\d+/)
          job.perform(message)
        end

        it "creates transaction even on failure" do
          allow_any_instance_of(Box::Transaction).to receive(:execute!).and_raise(Exception.new)
          expect { job.perform(message) }.to raise_error(Exception)
          expect(Box::Transaction.count).to eq(1)
          expect(last_transaction.status).to eq("created")
        end

        it "reruns already present transactions" do
          Transaction.create(
            eref: "123", type: "credit", payload: "<\u0002\r",
            ebics_order_id: nil, ebics_transaction_id: nil, status: "created",
            account_id: 321, order_type: "AZV", amount: 100,
            user_id: nil, history: [], currency: nil, metadata: nil
          )
          expect_any_instance_of(Transaction).to receive(:execute!)
          job.perform(message)
          expect(Box::Transaction.count).to eq(1)
        end
      end
    end
  end
end
