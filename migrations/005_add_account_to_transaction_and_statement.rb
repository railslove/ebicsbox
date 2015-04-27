Sequel.migration do
  change do
    add_column :transactions, :account_id, Integer
    add_column :statements, :account_id, Integer
  end
end
