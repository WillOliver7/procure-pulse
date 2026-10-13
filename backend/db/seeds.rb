Supplier.destroy_all
PurchaseOrder.destroy_all

suppliers = [
  Supplier.create!(name: "Acme Industrial", country: "US"),
  Supplier.create!(name: "Global Parts", country: "BR"),
  Supplier.create!(name: "Precision Supply", country: "DE")
]

products = [
  ["Industrial Gloves", "Safety", 10.00],
  ["Industrial Gloves", "Safety", 12.00],
  ["Industrial Gloves", "Safety", 15.00],
  ["Steel Bolts", "Hardware", 2.50],
  ["Steel Bolts", "Hardware", 2.20],
  ["Safety Glasses", "Safety", 8.00]
]

products.each_with_index do |(name, category, price), index|
  supplier = suppliers[index % suppliers.length]

  order = PurchaseOrder.create!(
    supplier: supplier,
    reference: "PO-#{1001 + index}",
    ordered_at: Date.current - index.days,
    currency: index == 1 ? "BRL" : "USD",
    status: "completed"
  )

  order.purchase_order_items.create!(
    product_name: name,
    category: category,
    quantity: index == 2 ? 500 : 100,
    unit_price: price
  )
end