Sequel.migration do
  up do
    set_column_type :webhook_deliveries, :event_id, :integer, using: 'event_id::integer'
  end

  down do
    set_column_type :webhook_deliveries, :event_id, :string, using: 'event_id::text'
  end
end
