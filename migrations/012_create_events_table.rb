Sequel.migration do
  up do
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
    DB.extension :pg_json

    create_table :events do
      primary_key 'id'

      Integer 'account_id'
      String 'type'
      String 'public_id', type: :uuid, default: Sequel.function(:uuid_generate_v4)
      String 'payload', type: :json, default: Sequel.pg_json({})
      DateTime 'triggered_at', default: 'now()'
      String 'signature'
      String 'webhook_status', default: 'pending'
      Integer 'webhook_retries', default: 0
    end
  end

  down do
    drop_table(:events)
  end
end
