Sequel.migration do
  up do
    add_column :subscribers, :ini_letter, String
    add_column :subscribers, :submitted_at, DateTime
  end

  down do
    drop_column :subscribers, :submitted_at
    drop_column :subscribers, :ini_letter
  end
end
