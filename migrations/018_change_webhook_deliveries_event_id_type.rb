Sequel.migration do
  change do
    alter_table(:webhook_deliveries) do
      set_column_type :event_id, Integer, using: 'event_id::int'
    end
  end
end
