require 'bundler'
Bundler.setup

require 'cmxl'
require 'pp'

require_relative './lib/epics/box/configuration'
configuration = Epics::Box::Configuration.new

# Setup database connection
require 'sequel'
DB ||= Sequel.connect(configuration.database_url, max_connections: 10)

# Load models
require_relative './lib/epics/box/models/statement'
require_relative './lib/epics/box/models/bank_statement'

Epics::Box::Statement.where(iban: nil).all.each do |statement|
  if bs = statement.bank_statement
    puts "Needs update: #{statement.id}"
  end
end
