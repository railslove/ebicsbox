module Epics
  module Box
    module Jobs
      RSpec.describe FetchStatements do
        describe '.process!' do
          let(:account) { Account.create(host: "HOST") }
          let!(:subscriber) { account.add_subscriber(signature_class: 'T', activated_at: 1.day.ago) }

          def exec_process
            described_class.process!(account_ids: [account.id])
          end

          context 'last import happened at least one day ago' do
            let(:client) { double('Epics Client') }

            before do
              account.imported_at!(1.day.ago)
              allow_any_instance_of(Subscriber).to receive(:client) { client }
              allow(client).to receive(:STA).and_return(File.read('spec/fixtures/mt940.txt'))
            end

            it 'fetches statements from remote server' do
              exec_process
              expect(account.transport_client).to have_received(:STA)
            end

            it 'adds info that a new import happened' do
              expect_any_instance_of(Account).to receive(:imported_at!)
              exec_process
            end

            it 'creates local statements for each remote record' do
              expect(described_class).to receive(:create_statement).at_least(:once)
              exec_process
            end
          end
        end

        describe '.create_statement' do
          let(:data) do
            double('MT940 Transaction',
              information: 'test',
              date: '2015-06-20',
              entry_date: '2015-06-20',
              amount_in_cents: 100_24,
              sign: 1,
              debit?: true,
              swift_code: 'swift_code',
              reference: 'reference',
              bank_reference: 'bank_reference',
              bic: 'bic',
              iban: 'iban',
              name: 'name',
              information: 'information',
              description: 'description',
              sepa: {
                "EREF" => 'my-eref',
                "MREF" => 'my-mref',
                "SVWZ" => 'my-svwz',
                "CRED" => 'my-cred',
              }
            )
          end

          def exec_create_action
            described_class.create_statement(1, data, "raw_data")
          end

          context 'the statement was already imported' do
            before { Statement.create(sha: 'dea7111a8406e27cfc8bf5f49c5d40898402b0b584b3285f069170a36f9eec31') }

            it 'does not create a statement' do
              expect { exec_create_action }.to_not change{ Statement.count }
            end
          end

          context 'statement is new' do
            it 'extracts subdata from sepa subtree' do
              exec_create_action
              expect(Statement.last.values).to match(hash_including(
                eref: 'my-eref',
                mref: 'my-mref',
                svwz: 'my-svwz',
                creditor_identifier: 'my-cred',
              ))
            end
          end
        end

        describe '.link_statement_to_transaction' do
          let(:statement) { Statement.create(eref: 'eref-123') }

          def exec_link_action
            described_class.link_statement_to_transaction(1, statement)
          end

          context 'no transaction could be found' do
            it 'does not trigger a webhook' do
              expect(Event).to_not receive(:statement_created)
              exec_link_action
            end
          end

          context 'transaction exists' do
            let!(:transaction) { Transaction.create(eref: statement.eref) }

            context 'statement is a credit' do
              before { statement.update(debit: false) }

              it 'sets correct transaction state' do
                expect_any_instance_of(Transaction).to receive(:set_state_from).with('credit_received')
                exec_link_action
              end

              skip 'triggers a webhook' do
                expect(Event).to receive(:statement_created)
                exec_link_action
              end
            end

            context 'statement is a debit' do
              before { statement.update(debit: true) }

              it 'sets correct transaction state' do
                expect_any_instance_of(Transaction).to receive(:set_state_from).with('debit_received')
                exec_link_action
              end

              it 'triggers a webhook' do
                expect(Queue).to receive(:trigger_webhook).at_least(:once)
                exec_link_action
              end
            end
          end
        end
      end
    end
  end
end
