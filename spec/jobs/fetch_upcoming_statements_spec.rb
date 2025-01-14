# frozen_string_literal: true

require "spec_helper"
require "active_support/all"

module Box
  module Jobs
    RSpec.describe FetchUpcomingStatements do
      subject(:job) { described_class.new }
      let(:account) { Account.create(host: "HOST", iban: "iban1234567") }
      let!(:ebics_user) { account.add_ebics_user(signature_class: "T", activated_at: 1.day.ago) }

      describe "#perform" do
        it "raises error when no account id given" do
          expect { job.perform(nil) }.to raise_error(FetchUpcomingStatementsError)
        end

        it "fetches statements for provided account" do
          allow(job).to receive(:fetch_for_account).with(account)
          job.perform(account.id)
        end

        it "sets default daterange if not provided" do
          allow(job).to receive(:fetch_for_account).and_return(true)
          job.perform(account.id)
          expect(job.send(:safe_from)).to eql(Date.today)
          expect(job.send(:safe_to)).to eql(30.days.from_now.to_date)
        end

        it "raises error when account uses camt instead of mt940" do
          account.update(statements_format: "camt53")
          expect(account).not_to receive(:transport_client)
          expect(Box.logger).to(
            receive(:info)
              .with("[Jobs::FetchUpcomingStatements] Skip VMK for #{account.id}. Currently only MT942 is supported")
          )

          job.perform(account.id)
        end
      end

      describe ".fetch_for_account" do
        let(:client) { double("Epics Client") }
        let(:import_file) { File.read("spec/fixtures/multiple-transactions.mt942") }

        before do
          allow_any_instance_of(EbicsUser).to receive(:client) { client }
          allow(client).to receive(:VMK).and_return(import_file)
          allow(Account).to(
            receive(:[]).and_return(double("account", organization: double("orga", webhook_token: "token")))
          )

          allow(BusinessProcesses::ImportBankStatement).to receive(:from_cmxl).and_call_original
          allow(BusinessProcesses::ImportStatements).to receive(:from_bank_statement).and_call_original
        end

        context "with handelsbank format" do
          before { Cmxl.config[:strip_headers] = true }
          after { Cmxl.config[:strip_headers] = false }

          it "imports all bank statements" do
            included_vmk = 3

            job.fetch_for_account(account)

            expect(BusinessProcesses::ImportBankStatement).to(
              have_received(:from_cmxl).exactly(included_vmk).times
            )
          end

          xit "updates the account balance" do
            job.fetch_for_account(account)

            expect(account.reload.balance_in_cents).to eql(0.0)
          end
        end

        context "with unstructured headers" do
          let(:import_file) { File.read("spec/fixtures/master_diesel_vmk_data.txt") }
          before { Cmxl.config[:strip_headers] = true }
          after { Cmxl.config[:strip_headers] = false }

          it "imports all bank statements" do
            included_vmk = 2

            job.fetch_for_account(account)

            expect(BusinessProcesses::ImportBankStatement).to(
              have_received(:from_cmxl).exactly(included_vmk).times
            )
          end

          xit "updates the account balance" do
            job.fetch_for_account(account)

            expect(account.reload.balance_in_cents).to eql(0.0)
          end
        end

        context "with structured header" do
          let(:import_file) { File.read("spec/fixtures/single_with_headers.mt940") }
          before { Cmxl.config[:strip_headers] = true }
          after { Cmxl.config[:strip_headers] = false }

          it "imports all bank statements" do
            included_vmk = 1

            job.fetch_for_account(account)

            expect(BusinessProcesses::ImportBankStatement).to(
              have_received(:from_cmxl).exactly(included_vmk).times
            )
          end
        end

        it "imports all statements for all bank statements" do
          bank_statements_for_this_account = 3 # One bank statement is for another account, such as a sub-account

          job.fetch_for_account(account)

          expect(BusinessProcesses::ImportStatements).to(
            have_received(:from_bank_statement).exactly(bank_statements_for_this_account).times
          )
        end

        it "does nothing when no data is provided" do
          allow(client).to receive(:VMK).and_return(nil)

          job.fetch_for_account(account)

          expect(BusinessProcesses::ImportBankStatement).not_to have_received(:from_cmxl)
          expect(BusinessProcesses::ImportStatements).not_to have_received(:from_bank_statement)
        end

        context "with timeframe" do
          before { job.send(:options=, from: Date.new(2019, 6, 1), to: Date.new(2019, 10, 31)) }

          it "fetches statements from remote server" do
            job.fetch_for_account(account)

            expect(account.transport_client).to have_received(:VMK).with("2019-06-01", "2019-10-31")
          end
        end

        context "without timeframe" do
          it "fetches statements from remote server" do
            job.fetch_for_account(account)

            expect(account.transport_client).to(
              have_received(:VMK).with(Date.today.to_s, 30.days.from_now.to_date.to_s)
            )
          end
        end
      end
    end
  end
end
