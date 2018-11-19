require 'sequel'
# Load application
require './config/configuration'

# namespace :jruby do
#   desc 'Build jruby classes'
#   task 'build' do
#     Dir["lib/**/*.rb"].each do |file|
#       if system("jrubyc #{file}")

#         puts " ---> Processing: #{file}"

#         File.write(file, 'load __FILE__.sub(/\.rb$/, ".class")')
#       else
#         puts " ---> Failed: #{file}"
#         exit(1)
#       end
#     end
#   end
# end

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

# namespace :db do
#   Sequel.extension :migration
#   DB = Sequel.connect(Box::Configuration.new.database_url)

#   desc "Perform migration up/down to VERSION"
#   task :to, :version do |_, args|
#     if args[:version].nil?
#       puts 'You must specify a migration version'
#       exit false
#     end

#     version = args[:version].to_i
#     raise "No VERSION was provided" if version.nil?
#     Sequel::Migrator.run(DB, "migrations", :target => version)
#     puts "<= sq:migrate:to version=[#{version}] executed"
#   end
# end

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
