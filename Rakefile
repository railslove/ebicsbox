# Load swagger rake task
spec = Gem::Specification.find_by_name 'ruby-swagger'
load "#{spec.gem_dir}/lib/tasks/swagger.rake"

# Load application
require './lib/epics/box'

namespace :jruby do
  desc 'Build jruby classes'
  task 'build' do
    Dir["lib/**/*.rb"].each do |file|
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
