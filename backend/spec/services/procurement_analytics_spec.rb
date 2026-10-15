
require "rails_helper"

RSpec.describe ProcurementAnalytics do
  describe "#call" do
    it "calculates total spend and groups it by supplier and category" do
      supplier = Supplier.create!(
        name: "Test Supplier",
        country: "Brazil"
      )

      order = PurchaseOrder.create!(
        supplier: supplier,
        reference: "PO-ANALYTICS-001",
        ordered_at: Date.current,
        currency: "USD",
        status: "approved"
      )

      PurchaseOrderItem.create!(
        purchase_order: order,
        product_name: "Steel",
        category: "Raw Materials",
        quantity: 10,
        unit_price: BigDecimal("12.50")
      )

      client = instance_double(ExchangeRates::Client)
      allow(client).to receive(:rate)
        .with(from: "USD", to: "USD")
        .and_return(BigDecimal("1"))

      result = described_class.new(
        exchange_rate_client: client
      ).call

      expect(result[:currency]).to eq("USD")
      expect(result[:order_count]).to eq(1)
      expect(result[:total_spend_usd]).to eq("125.0")
      expect(result[:spend_by_supplier]).to eq(
        [{ name: "Test Supplier", spend_usd: "125.0" }]
      )
      expect(result[:spend_by_category]).to eq(
        [{ name: "Raw Materials", spend_usd: "125.0" }]
      )
    end
  end
end
