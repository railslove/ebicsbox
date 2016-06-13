Sequel.migration do
  change do
    alter_table(:organizations) do
      set_column_not_null :webhook_token
    end
  end
end
