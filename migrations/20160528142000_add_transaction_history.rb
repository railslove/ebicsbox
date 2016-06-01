Sequel.migration do
  up do
    add_column :transactions, :history, String, type: :json, default: Sequel.pg_json([])
  end

  down do
    drop_column :transactions, :history
  end
end
