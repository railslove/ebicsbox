Sequel.migration do
  up do
    add_column :transactions, :created_at, DateTime
  end

  down do
    drop_column :transactions, :created_at
  end
end
