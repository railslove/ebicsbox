# frozen_string_literal: true

Sequel.migration do
  change do
    add_column :statements, :expected, :boolean
    add_column :statements, :reversal, :boolean
  end
end
