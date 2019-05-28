require 'spec_helper'
require 'json'

module Box
  module Jobs
    RSpec.describe CheckActivation do
      subject(:job) { described_class.new }
      let(:account) { Account.create }
      let!(:ebics_user) { account.add_ebics_user(ini_letter: 'foobar') }

      def execute
        job.perform
      end

      it 'tries to activate the account' do
        expect_any_instance_of(EbicsUser).to receive(:activate!)
        execute
      end

      context 'activation failed' do
        it 'logs an info' do
          expect { execute }.to have_logged_message("[Jobs::CheckActivation] Failed to activate ebics_user! ebics_user_id=#{ebics_user.id}")
        end
      end

      context 'activated' do
        before { allow_any_instance_of(EbicsUser).to receive(:activate!).and_return(true) }

        it 'logs an info' do
          expect { execute }.to have_logged_message("[Jobs::CheckActivation] Activated ebics_user! ebics_user_id=#{ebics_user.id}")
        end
      end
    end
  end
end
