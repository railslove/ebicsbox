# frozen_string_literal: true

require "database_cleaner-sequel"

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning do
      DB.transaction(rollback: :always, auto_savepoint: true) do
        example.run
      end
    end
  end
end
