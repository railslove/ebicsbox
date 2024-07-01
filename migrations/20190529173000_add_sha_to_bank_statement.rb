# frozen_string_literal: true

Sequel.migration do
  up do
    add_column :bank_statements, :sha, String
    add_index :bank_statements, :sha

    require "rake"
    load "Rakefile"
    Rake::Task["migration_tasks:calculate_bank_statements_sha"].invoke
  end

  down do
    drop_column :bank_statements, :sha
  end
end
