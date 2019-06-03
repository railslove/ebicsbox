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
  env = ENV.fetch('RACK_ENV', :development)
  if %w[development test].include?(env.to_s)
    # Load environment from file
    require 'dotenv'
    Dotenv.load
  end

  desc 'calculate SHAs of bank_statements'
  task :calculate_bank_statements_sha do
    i = 0
    statements = Box::BankStatement.where(sha: nil)

    p "Found #{statements.count} without a SHA, recalculating"

    statements.each do |bs|
      payload = [
        bs.account_id,
        bs.year,
        bs.source
      ]

      bs.update(sha: Digest::SHA2.hexdigest(payload.flatten.join).to_s)

      i += i
    end

    p "Updated #{i} bank statements"
  end
end