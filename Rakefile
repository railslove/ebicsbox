# require "bundler/gem_tasks"
require 'dotenv'
Dotenv.load

namespace :jruby do
  task 'build' do

    Dir["lib/**/queue.rb", "lib/**/server.rb", "lib/**/jobs/*.rb", "lib/**/models/*.rb"].each do |file|
      if system("jrubyc #{file}")

        puts " ---> Processing: #{file}"

        File.write(file, 'load __FILE__.sub(/\.rb$/, ".class")')
      else
        puts " ---> Failed: #{file}"
        exit(1)
      end
    end

  end
end

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "migrations")
    end
  end
end
