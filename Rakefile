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

namespace :after_migration do
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

  desc 'recalculate SHAs of statements'
  task :recalculate_statements_sha do
    env = ENV.fetch('RACK_ENV', :development)
    if env.to_s != 'production'
      # Load environment from file
      require 'dotenv'
      Dotenv.load
    end

    require './config/bootstrap'
    require './box/models/statement'
    require './lib/checksum_generator'


    i = 0
    statements = Box::Statement.where(sha: nil)

    p "Found #{statements.count}  without a SHA."
    next if statements.count.zero?

    p 'Recalculating  SHAs.'

    statements.each do |statement|
      eref = statement.respond_to?(:eref) ? statement.eref : statement.sepa['EREF']
      mref = statement.respond_to?(:mref) ? statement.mref : statement.sepa['MREF']
      svwz = statement.respond_to?(:svwz) ? statement.svwz : statement.sepa['SVWZ']

      payload = [
        statement.bank_statement&.remote_account,
        statement.date,
        statement.amount,
        statement.iban,
        statement.name,
        statement.sign,
        eref,
        mref,
        svwz,
        statement.information.gsub(/\s/, '')
      ]

      sha = ChecksumGenerator.from_payload(payload)

      next if Box::Statement.find(sha: sha) # duplicates.. let's not update them

      statement.update(sha: ChecksumGenerator.from_payload(payload))
      i += 1
    end

    p "Updated #{i} Statement SHAs."
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
