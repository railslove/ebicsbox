Sequel.migration do
  up do
    create_table :imports do
      primary_key :id
      Date :date
      Integer :duration
      Integer :transactions_count
    end
  end

  down do
    drop_table(:imports)
  end
end
