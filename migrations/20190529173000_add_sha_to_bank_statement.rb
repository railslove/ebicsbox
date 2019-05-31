# frozen_string_literal: true

require 'digest'

Sequel.migration do
  up do
    add_column :bank_statements, :sha, String
    add_index :bank_statements, :sha
  end

  down do
    drop_column :bank_statements, :sha
  end
end
