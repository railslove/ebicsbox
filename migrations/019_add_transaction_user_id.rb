Sequel.migration do
  up do
    add_column :transactions, :user_id, Integer
  end

  down do
    drop_column :transactions, :user_id
  end
end
