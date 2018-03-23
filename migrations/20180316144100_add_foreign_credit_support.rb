Sequel.migration do
  change do
    add_column :transactions, :currency, String, default: 'EUR'
    add_column :transactions, :metadata, String, type: :json, default: Sequel.pg_json({})
  end
end
