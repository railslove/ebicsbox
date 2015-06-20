module Epics
  module Box
    RSpec.describe Account do
      describe '.all_ids' do
        it 'returns an empty array if no accounts are created yet' do
          expect(Account.all_ids).to eq([])
        end

        it 'returns all account ids' do
          accounts = Array.new(2).map { Account.create }
          expect(Account.all_ids).to eq(accounts.map(&:id))
        end
      end
    end
  end
end
