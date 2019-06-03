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

      bs.update(sha: Digest::SHA2.hexdigest(payload.flatten.join).to_s)

      i += 1
    end

    p "Updated #{i} Bank Statement SHAs."
  end
end
