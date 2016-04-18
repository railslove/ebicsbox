Sequel.migration do
  up do
    add_column :accounts, :statements_format, String, default: 'mt940'
  end

  down do
    drop_column :accounts, :statements_format
  end
end
