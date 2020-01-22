# frozen_string_literal: true

require 'sequel'
# Load application
require './config/configuration'

namespace :generate do
  desc 'Generate a timestamped, empty Sequel migration.'
  task :migration, :name do |_, args|
    if args[:name].nil?
      puts 'You must specify a migration name (e.g. rake generate:migration[create_events])!'
      exit false
    end

    content = "Sequel.migration do\n  up do\n    \n  end\n\n  down do\n    \n  end\nend\n"
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    filename = File.join(File.dirname(__FILE__), 'migrations', "#{timestamp}_#{args[:name]}.rb")

    File.open(filename, 'w') do |f|
      f.puts content
    end

    puts "Created the migration #{filename}"
  end
end

namespace :migration_tasks do
  desc 'calculate SHAs of bank_statements'
  task :calculate_bank_statements_sha do
    env = ENV.fetch('RACK_ENV', :development)
    if env.to_s != 'production'
      # Load environment from file
      require 'dotenv'
      Dotenv.load
    end

    require './config/bootstrap'
    require './box/models/bank_statement'
    require './lib/checksum_generator'

    i = 0
    statements = Box::BankStatement.where(sha: nil)

    p "Found #{statements.count} Bank Statements without a SHA."
    next if statements.count.zero?

    p 'Recalculating Bank Statement SHAs.'

    statements.each do |bs|
      payload = [
        bs.account_id,
        bs.year,
        bs.content
      ]

      bs.update(sha: ChecksumGenerator.from_payload(payload))

      i += 1
    end

    p "Updated #{i} Bank Statement SHAs."
  end

  # this should ONLY be run via migration migrations/20191217114900_recalculate_statement_sha.rb
  desc 'calculate new SHA'
  task :calculate_new_sha do
    env = ENV.fetch('RACK_ENV', :development)
    if env.to_s != 'production'
      # Load environment from file
      require 'dotenv'
      Dotenv.load
    end

    require './config/bootstrap'
    require './box/models/account'
    require './box/models/statement'
    require './box/models/bank_statement'
    require './lib/checksum_updater'

    # safe guard to only run this task when temp checksum field is available
    next unless Box::Statement.columns.include?(:sha2)

    account_ids = Box::Account.all_active_ids
    account_ids.each.with_index(1) do |account_id, idx|
      pp "Processing Account #{idx} / #{account_ids.count}"

      bank_statements = Box::BankStatement.where(account_id: account_id).all
      bank_statements.each do |bank_statement|
        parser = bank_statement.content.starts_with?(':') ? Cmxl : CamtParser::Format053::Statement
        begin
          result = parser.parse(bank_statement.content)
          transactions = result.is_a?(Array) ? result.first.transactions : result.transactions

          transactions.each do |transaction|
            ChecksumUpdater.new(transaction, bank_statement.remote_account).call
          end
        rescue => e
          p '--- ERROR ---'
          p bank_statement.id
          p e
          p '--- !ERROR ---'
        end
      end
    end

    Box::Statement.where(sha2: nil).each do |statement|
      remote_account = statement&.bank_statement&.remote_account
      payload = ::ChecksumUpdater.new(statement, remote_account).send(:new_checksum_payload)
      sha = ChecksumGenerator.from_payload(payload)
      statement.update(sha2: sha)
    rescue Sequel::UniqueConstraintViolation
      p '--- NON-UNIQUE STATEMENT ERROR ---'
      p statement.id
      p e
      p '--- !NON-UNIQUE STATEMENT ERROR ---'
    end; nil
  end

  desc 'copies partner value to ebics_users'
  task :copy_partners do
    env = ENV.fetch('RACK_ENV', :development)
    if env.to_s != 'production'
      # Load environment from file
      require 'dotenv'
      Dotenv.load
    end

    require './config/bootstrap'
    require './box/models/ebics_user'

    Box::EbicsUser.where(partner: nil).each do |ebics_user|
      ebics_user.update(partner: ebics_user.accounts.first&.partner)
    end
  end
end
