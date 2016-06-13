# Load swagger rake task
spec = Gem::Specification.find_by_name 'ruby-swagger'
load "#{spec.gem_dir}/lib/tasks/swagger.rake"

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
