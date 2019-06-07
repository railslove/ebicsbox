Sequel.migration do
  up do
    add_column :statements, :settled, :boolean, default: true
  end

  down do
    remove_column :statements, :settled
  end
end
