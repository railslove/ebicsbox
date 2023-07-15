# frozen_string_literal: true

Sequel.migration do
  up do
    add_column :statements, :msg_id, String
    add_column :transactions, :msg_id, String
  end

end
