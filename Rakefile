# require "bundler/gem_tasks"

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
