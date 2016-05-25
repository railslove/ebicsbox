Sequel.migration do
  up do
    add_column :accounts, :config, String, type: :json, default: Sequel.pg_json({})
  end

  down do
    drop_column :accounts, :config
  end
end
