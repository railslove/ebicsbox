Sequel.migration do
  change do
    add_column :imports, :account_id, Integer
  end
end
