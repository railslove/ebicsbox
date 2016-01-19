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
