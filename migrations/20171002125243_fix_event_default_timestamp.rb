Sequel.migration do
  up do
    set_column_default :events, :triggered_at, Sequel.function(:now)
  end
end
