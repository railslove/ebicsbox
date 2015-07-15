require 'json'

module Epics
  module Box
    module Jobs
      RSpec.describe CheckActivation do
        let(:account) { Account.create }

        def execute
          described_class.process!(account_id: account.id)
        end

        it 'tries to activate the account' do
          expect_any_instance_of(Account).to receive(:activate!)
          execute
        end

        context 'activation failed' do
          it 'logs an info' do
            expect { execute }.to have_logged_message("[Jobs::CheckActivation] Failed to activate account! account_id=#{account.id}")
          end
        end

        context 'activated' do
          before { allow_any_instance_of(Account).to receive(:activate!).and_return(true) }

          it 'logs an info' do
            expect { execute }.to have_logged_message("[Jobs::CheckActivation] Activated account! account_id=#{account.id}")
          end
        end
      end
    end
  end
end
