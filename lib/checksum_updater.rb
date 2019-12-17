# frozen_string_literal: true

require_relative './checksum_generator'
require_relative '../box/models/statement'

class ChecksumUpdater
  PARSERS = { 'mt940' => Cmxl, 'camt53' => CamtParser::Format053::Statement }.freeze
  attr_accessor :bank_statement

  def initialize(bank_statement)
    self.bank_statement = bank_statement
  end

  def call
    parse_bank_statement(bank_statement).each do |transaction|
      old_checksum = ChecksumGenerator.from_payload(old_checksum_payload(transaction))
      new_checksum = ChecksumGenerator.from_payload(new_checksum_payload(transaction))

      trx = Box::Statement.find(sha2: old_checksum)
      trx&.update(sha: new_checksum)
    end
  end

  private

  def parse_bank_statement(bank_statement)
    parser = PARSERS.fetch(bank_statement.account.statements_format, Cmxl)
    result = parser.parse(bank_statement.content)
    result.is_a?(Array) ? result.first.transactions : result.transactions
  end

  def new_checksum_payload(transaction)
    return [bank_statement.remote_account, transaction.transaction_id] if transaction.try(:transaction_id).present?

    old_checksum_payload(transaction)
  end

  def old_checksum_payload(transaction)
    eref = transaction.respond_to?(:eref) ? transaction.eref : transaction.sepa['EREF']
    mref = transaction.respond_to?(:mref) ? transaction.mref : transaction.sepa['MREF']
    svwz = transaction.respond_to?(:svwz) ? transaction.svwz : transaction.sepa['SVWZ']

    [
      bank_statement.remote_account,
      transaction.date,
      transaction.amount_in_cents,
      transaction.iban,
      transaction.name,
      transaction.sign,
      eref,
      mref,
      svwz,
      transaction.information.gsub(/\s/, '')
    ]
  end
end
