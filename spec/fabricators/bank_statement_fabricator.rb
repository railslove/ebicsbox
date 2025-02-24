# frozen_string_literal: true

require_relative "../../box/models/bank_statement"

Fabricator(:bank_statement, from: "Box::BankStatement") do
  account { Fabricate(:account) }
  fetched_on { Date.today }
  sha { Faker::Crypto.sha256 }
end

Fabricator(:camt_statement, from: :bank_statement) do
  sequence { "130000005" }
  year { 2013 }
  remote_account { "iban1234567" }
  opening_balance { 33.06 }
  closing_balance { 23.06 }
  transaction_count { 4 }
  content { File.read("spec/fixtures/camt/statement-part.xml") }
end

Fabricator(:mt940_statement, from: :bank_statement) do
  sequence { "00006/004" }
  year { 2017 }
  remote_account { "10020030/1234567" }
  opening_balance { 57868.58 }
  closing_balance { 57839.48 }
  transaction_count { 2 }
  content { File.read("spec/fixtures/single_valid_swift.mt940") }
end
