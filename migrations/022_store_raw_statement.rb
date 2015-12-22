Sequel.migration do
  up do
    add_column :statements, :raw_data, String
  end

  down do
    drop_column :statements, :raw_data
  end
end
