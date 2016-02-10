lib = File.expand_path("../..", __FILE__)
$:.unshift(lib)

# Load configuration
require_relative './configuration'

# Load dependencies
# TODO: Remove them here and load where really used!
require 'grape'
require 'grape-entity'
require 'sequel'
require 'cmxl'
require 'httparty'
require 'json'
require 'nokogiri'
require 'epics'
require 'sepa_king'
require 'base64'

# Extensions to add swagger documentation methods
require 'ruby-swagger/grape/grape'

module Box
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end
end
# Init database connection
DB = Sequel.connect(Box.configuration.database_url, max_connections: 10)

# Enable json extensions
Sequel.extension :pg_json
DB.extension :pg_json

require_relative "./api"
require_relative "./worker"
require_relative "./queue"
require_relative "./models/account"
require_relative "./models/organization"
require_relative "./models/statement"
require_relative "./models/subscriber"
require_relative "./models/transaction"
require_relative "./models/user"
