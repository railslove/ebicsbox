# frozen_string_literal: true

Sequel.migration do
  up do
    if from(:statements).select(:public_id).all? { |s| s[:public_id].nil? }
      # if all are empty, drop column and re-add to recalculate public-ids
      drop_column :statements, :public_id
      add_column :statements, :public_id, String, type: :uuid, default: Sequel.function(:uuid_generate_v4)
    else
      # if at least a single public-id is already set, just update the default for
      # new records to have a correctly generated public_id
      set_column_default :statements, :public_id, Sequel.function(:uuid_generate_v4)
    end
  end

  down do
    # noop
  end
end
