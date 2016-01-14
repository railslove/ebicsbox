Sequel.migration do
  up do
    add_column :accounts, :balance_in_cents, Integer
    add_column :accounts, :balance_date, Date
  end

  down do
    drop_column :accounts, :balance_date
    drop_column :accounts, :balance_in_cents
  end
end
