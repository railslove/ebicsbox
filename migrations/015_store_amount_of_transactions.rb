Sequel.migration do
  change do
    add_column :transactions, :amount, Integer
    rename_column :statements, :amount_cents, :amount
  end
end
