Sequel.migration do
  up do
    DB.extension :pg_json

    create_table :webhook_deliveries do
      primary_key 'id'
      String 'event_id'
      DateTime 'delivered_at'
      Text 'response_body'
      String 'reponse_headers', type: :json, default: Sequel.pg_json({})
      Integer 'response_status'
      Integer 'response_time'
    end
  end

  down do
    drop_table(:webhook_deliveries)
  end
end
