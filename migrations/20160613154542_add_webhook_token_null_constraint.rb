require 'SecureRandom'
require_relative '../box/models/organization'

Sequel.migration do
  up do
    Box::Organization.where('webhook_token IS NULL or webhook_token = ?', '').each do |orga|
      orga.webhook_token = SecureRandom.hex
      orga.savegst
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
