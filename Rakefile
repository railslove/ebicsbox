# Setup environment
# require 'dotenv'
# Dotenv.load

# Require dependencies from gemfile
# Bundler.require

# Load swagger rake task
# spec = Gem::Specification.find_by_name 'ruby-swagger'
# load "#{spec.gem_dir}/lib/tasks/swagger.rake"

# Load application
# require './lib/epics/box'

namespace :jruby do
  desc 'Build jruby classes'
  task 'build' do
    Dir["lib/**/queue.rb", "lib/**/server.rb", "lib/**/jobs/*.rb", "lib/**/models/*.rb"].each do |file|
      if system("jrubyc #{file}")

        puts " ---> Processing: #{file}"

        File.write(file, 'require_relative __FILE__.sub(/\.rb$/, ".class")')
      else
        puts " ---> Failed: #{file}"
        exit(1)
      end
    end
  end
end

# namespace :db do
#   desc "Run migrations"
#   task :migrate, [:version] do |t, args|
#     require "sequel"
#     Sequel.extension :migration
#     db_url = ENV.fetch("TEST") ? ENV.fetch("TEST_DATABASE_URL") : ENV.fetch("DATABASE_URL")
#     DB = Sequel.connect(db_url)
#     if args[:version]
#       puts "Migrating to version #{args[:version]} on #{db_url}"
#       Sequel::Migrator.run(DB, "migrations", target: args[:version].to_i)
#     else
#       puts "Migrating to latest on #{db_url}"
#       Sequel::Migrator.run(DB, "migrations")
#     end
#   end
# end
