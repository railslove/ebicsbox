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

namespace :enqueue do
  env = ENV.fetch('RACK_ENV', :development)
  if %w[development test].include?(env.to_s)
    # Load environment from file
    require 'dotenv'
    Dotenv.load
  end

  require_relative './config/bootstrap'
  require_relative './box/queue'

  desc 'enqueue account statement fething'
  task :fetch_account_statements do
    Box::Queue.fetch_account_statements
  end

  desc 'enqueue updating processing status'
  task :update_processing_status do
    # run every 5 hours only
    next unless ((Time.now.to_i / 3600) % 5).zero?

    Box::Queue.update_processing_status
  end
end
