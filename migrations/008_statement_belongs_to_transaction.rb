Sequel.migration do
  change do
    add_column :statements, :transaction_id, Integer
  end
end
