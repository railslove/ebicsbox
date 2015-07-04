module Epics
  module Box
    RSpec.describe Statement do
      describe '.paginated_by_account' do
        let(:account) { Account.create(iban: SecureRandom.uuid) }
        let!(:statements) { [nil, nil, nil].map { Statement.create(account_id: account.id) } }

        it 'only account is required' do
          expect(described_class.paginated_by_account(account.id).all).to eq(statements)
        end

        it 'allows to limit the size of returned dataset' do
          expect(described_class.paginated_by_account(account.id, per_page: 2).all).to eq(statements.take(2))
        end

        it 'allows to specify offset of returned dataset' do
          expect(described_class.paginated_by_account(account.id, per_page: 2, page: 2).all).to eq([statements[2]])
        end
      end

      describe '#credit?' do
        it 'returns true if record is a credit' do
          subject.debit = false
          expect(subject.credit?).to eq(true)
        end

        it 'returns false if record is a debig' do
          subject.debit = true
          expect(subject.credit?).to eq(false)
        end
      end

      describe '#debit?' do
        it 'returns true if record is a debit' do
          subject.debit = true
          expect(subject.debit?).to eq(true)
        end

        it 'returns false if record is a debig' do
          subject.debit = false
          expect(subject.debit?).to eq(false)
        end
      end

      describe '#transaction' do
        let!(:statement) { Statement.create(eref: transaction.eref, transaction_id: transaction.id) }
        let!(:transaction) { Transaction.create(eref: SecureRandom.uuid) }

        it 'returns the connected transaction' do
          expect(statement.transaction).to eq(transaction)
        end

      end
    end
  end
end
