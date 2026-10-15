
class ProcurementAnalytics
  def initialize(exchange_rate_client: ExchangeRates::Client.new)
    @exchange_rate_client = exchange_rate_client
    @rates = {}
  end

  def call
    orders = PurchaseOrder.includes(
      :supplier,
      :purchase_order_items
    )

    total_spend = BigDecimal("0")
    supplier_spend = Hash.new { |hash, key| hash[key] = BigDecimal("0") }
    category_spend = Hash.new { |hash, key| hash[key] = BigDecimal("0") }

    orders.each do |order|
      order.purchase_order_items.each do |item|
        rate = exchange_rate(order.currency)
        item_spend = item.quantity * item.unit_price * rate

        total_spend += item_spend
        supplier_spend[order.supplier.name] += item_spend
        category_spend[item.category] += item_spend
      end
    end

    {
      currency: "USD",
      order_count: orders.size,
      total_spend_usd: money(total_spend),
      spend_by_supplier: format_breakdown(supplier_spend),
      spend_by_category: format_breakdown(category_spend)
    }
  end

  private

  def exchange_rate(currency)
    @rates[currency] ||= @exchange_rate_client.rate(
      from: currency,
      to: "USD"
    )
  end

  def format_breakdown(values)
    values
      .sort_by { |name, amount| -amount }
      .map do |name, amount|
        {
          name: name,
          spend_usd: money(amount)
        }
      end
  end

  def money(amount)
    amount.round(2).to_s("F")
  end
end
