require 'securerandom'
require_relative '../box/models/organization'

Sequel.migration do
  up do
    Box::Organization.set_dataset :organizations
    Box::Organization.where('webhook_token IS NULL or webhook_token = ?', '').each do |orga|
      orga.webhook_token = SecureRandom.hex
      orga.save
    end
    alter_table(:organizations) do
      set_column_not_null :webhook_token
    end
  end

  down do
    alter_table(:organizations) do
      set_column_allow_null :webhook_token
    end
  end
end