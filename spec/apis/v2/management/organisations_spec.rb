# frozen_string_literal: true

require "spec_helper"

module Box
  RSpec.describe Apis::V2::Management::Organizations do
    include_context "admin user"

    describe "POST /organizations" do
      context "empty body" do
        before { post "management/organizations", {}, TestHelpers::VALID_HEADERS }

        it "rejects empty posts" do
          expect_status 400
        end

        it "contains a meaningful message" do
          expect_json "message", "Validation of your request's payload failed!"
        end

        it "highlights missing fields" do
          expect_json "errors",
            name: ["is missing", "is empty"],
            user: ["is missing"]
        end
      end

      context "valid body" do
        def do_request
          post "management/organizations", {name: "Test organization", user: {name: "Foo Bar"}}, TestHelpers::VALID_HEADERS
        end

        it "creates a new organization" do
          expect { do_request }.to change(Organization, :count).by(1)
        end

        it "creates a new admin" do
          expect { do_request }.to change(User.where(admin: true, name: "Foo Bar"), :count).by(1)
        end

        it "returns a 201 status" do
          do_request
          expect(response.status).to eq(201)
        end
      end
    end
  end
end
