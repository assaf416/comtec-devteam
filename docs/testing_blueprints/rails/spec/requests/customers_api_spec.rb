require "rails_helper"

RSpec.describe "Customers API", type: :request do
  describe "POST /api/v1/customers" do
    let(:valid_payload) do
      {
        customer: {
          name: "Acme Corp",
          email: "ops@acme.test"
        }
      }
    end

    let(:invalid_payload) do
      {
        customer: {
          name: "Missing Email Inc"
        }
      }
    end

    it "creates a customer" do
      post "/api/v1/customers", params: valid_payload, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Acme Corp")
      expect(json["id"]).to be_present
    end

    it "returns validation errors for invalid payload" do
      post "/api/v1/customers", params: invalid_payload, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("email")
    end
  end
end
