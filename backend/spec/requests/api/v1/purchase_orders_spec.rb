require "rails_helper"

RSpec.describe "API V1 Purchase Orders", type: :request do
  describe "GET /api/v1/purchase_orders" do
    it "returns purchase orders with suppliers and items" do
      auth = create_authenticated_user

      supplier = Supplier.create!(
        name: "Acme Supplies",
        country: "Brazil"
      )

      order = PurchaseOrder.create!(
        supplier: supplier,
        reference: "PO-TEST-001",
        ordered_at: Date.current,
        currency: "BRL",
        status: "approved"
      )

      PurchaseOrderItem.create!(
        purchase_order: order,
        product_name: "Steel",
        category: "Raw Materials",
        quantity: 10,
        unit_price: 25.50
      )

      get "/api/v1/purchase_orders", headers: auth[:headers]

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      result = body.find { |item| item["id"] == order.id }

      expect(result).not_to be_nil
      expect(result["supplier"]["name"]).to eq("Acme Supplies")
      expect(result["purchase_order_items"].size).to eq(1)
    end
  end
end
