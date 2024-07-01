# frozen_string_literal: true

require_relative "./checksum_generator"
require_relative "../box/models/statement"
require_relative "../box/business_processes/import_statements"

class ChecksumUpdater
  attr_accessor :transaction, :remote_account

  def initialize(transaction, remote_account)
    self.transaction = transaction
    self.remote_account = remote_account
  end

  def call
    old_checksum = ChecksumGenerator.from_payload(old_checksum_payload)
    new_checksum = ChecksumGenerator.from_payload(new_checksum_payload)

    Box::Statement.find(sha: old_checksum)&.update(sha2: new_checksum)
  end

  private

  def new_checksum_payload
    Box::BusinessProcesses::ImportStatements.checksum_attributes(transaction, remote_account)
  end

  def old_checksum_payload
    Box::BusinessProcesses::ImportStatements.payload_from_transaction_attributes(transaction, remote_account)
  end
end
