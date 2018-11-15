require 'spec_helper'
require 'json'

module Box
  module Jobs
    RSpec.describe CheckActivation do
      subject(:job) { described_class.new }
      let(:account) { Account.create }
      let(:subscriber) { account.add_subscriber({}) }

      def execute
        job.perform(subscriber.id)
      end

      it 'tries to activate the account' do
        expect_any_instance_of(Subscriber).to receive(:activate!)
        execute
      end

      context 'activation failed' do
        it 'logs an info' do
          expect { execute }.to have_logged_message("[Jobs::CheckActivation] Failed to activate subscriber! subscriber_id=#{subscriber.id}")
        end
      end

      context 'activated' do
        before { allow_any_instance_of(Subscriber).to receive(:activate!).and_return(true) }

        it 'logs an info' do
          expect { execute }.to have_logged_message("[Jobs::CheckActivation] Activated subscriber! subscriber_id=#{subscriber.id}")
        end
      end
    end
  end
end
