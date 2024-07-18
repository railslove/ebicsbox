# frozen_string_literal: true

require "spec_helper"

module Box
  RSpec.describe Apis::Healthcheck do
    describe "GET /health" do
      it "returns a successful response" do
        get "/health"
        expect_status 200
      end

      it "returns the expected response body" do
        get "/health"
        expect_json "status", "ok"
      end
    end
  end
end
