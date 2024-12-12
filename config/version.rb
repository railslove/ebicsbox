# frozen_string_literal: true

module Box
  def self.version
    ENV["APP_VERSION"].to_s
  end
end
