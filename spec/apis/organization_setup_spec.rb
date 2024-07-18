# frozen_string_literal: true

require "spec_helper"

module Box
  RSpec.describe Apis::OrganizationSetup do
    let(:ui_initial_setup_feature) { true }
    before { allow(Box.configuration).to receive(:ui_initial_setup?).and_return(ui_initial_setup_feature) }

    describe "GET /setup" do
      it "returns a successful response" do
        get "/setup"
        expect_status 200
      end

      it "returns the expected response body" do
        get "/setup"
        expect(body).not_to be_empty
      end
    end

    describe "POST /setup" do
      it "returns a successful response" do
        organization = Fabricate(:organization, name: "Primary Organization")
        Box::User.create(organization_id: organization.id, name: "Primary user", access_token: "test-token", admin: true)

        post "/setup", organization: "New Organization", user_name: "New User"

        expect_status 201
      end

      it "returns the expected response body" do
        organization = Fabricate(:organization, name: "Primary Organization")
        Box::User.create(organization_id: organization.id, name: "Primary user", access_token: "test-token", admin: true)

        post "/setup", organization: "New Organization", user_name: "New User"

        expect_json "organization.name", "New Organization"
        expect_json "user.name", "New User"
      end

      it "updates the organization and user" do
        organization = Fabricate(:organization, name: "Primary Organization")
        Box::User.create(organization_id: organization.id, name: "Primary user", access_token: "test-token", admin: true)

        post "/setup", organization: "New Organization", user_name: "New User"

        expect(Organization.where(name: "New Organization").first).not_to be_nil
        expect(User.where(name: "New User").first).not_to be_nil
      end

      context "when the UI initial setup feature is disabled" do
        let(:ui_initial_setup_feature) { false }

        it "returns a 403" do
          post "/setup", organization: "New Organization", user_name: "New User"

          expect_status 403

          expect_json "error", "forbidden"
        end
      end

      context "when the default organization does not exist" do
        it "returns a 404" do
          Fabricate(:organization, name: "production Organization")
          post "/setup", organization: "New Organization", user_name: "New User"

          expect_status 404
        end
      end

      context "when the default user does not exist" do
        it "returns a 404" do
          Fabricate(:organization, name: "Primary Organization")
          post "/setup", organization: "New Organization", user_name: "New User"

          expect_status 404
        end
      end
    end
  end
end
