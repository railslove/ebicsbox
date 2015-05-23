Sequel.migration do
  change do
    add_column :transactions, :order_type, String
  end
end
