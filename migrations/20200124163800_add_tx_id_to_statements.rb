# frozen_string_literal: true

Sequel.migration do
  up do
    add_column :statements, :tx_id, String
  end

  down do
    drop_column :statements, :tx_id
  end
end
