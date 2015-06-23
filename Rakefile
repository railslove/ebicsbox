require "bundler/gem_tasks"

namespace :jruby do
  task 'build' do

    Dir["**/server*.rb", "**/beans*.rb"].each do |file|
      system("jrubyc #{file}")

      puts " ---> Processing: #{file}"

      File.write(file, 'load __FILE__.sub(/\.rb$/, ".class")')
    end

  end
end
