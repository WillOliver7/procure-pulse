require "rails_helper"

RSpec.describe "API V1 Analytics", type: :request do
  describe "GET /api/v1/analytics" do
    it "returns procurement analytics as JSON" do
      auth = create_authenticated_user

      analytics = {
        currency: "USD",
        order_count: 1,
        total_spend_usd: "125.0",
        spend_by_supplier: [
          { name: "Test Supplier", spend_usd: "125.0" }
        ],
        spend_by_category: [
          { name: "Raw Materials", spend_usd: "125.0" }
        ]
      }

      service = instance_double(ProcurementAnalytics, call: analytics)
      allow(ProcurementAnalytics).to receive(:new).and_return(service)

      get "/api/v1/analytics", headers: auth[:headers]

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["currency"]).to eq("USD")
      expect(body["order_count"]).to eq(1)
      expect(body["total_spend_usd"]).to eq("125.0")
      expect(body["spend_by_supplier"].first["name"])
        .to eq("Test Supplier")
      expect(body["spend_by_category"].first["name"])
        .to eq("Raw Materials")
    end
  end
end
