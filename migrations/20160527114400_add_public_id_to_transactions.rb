Sequel.migration do
  up do
    add_column :transactions, :public_id, :uuid, default: Sequel.function(:uuid_generate_v4), null: false
  end

  down do
    drop_column :transactions, :public_id
  end
end
