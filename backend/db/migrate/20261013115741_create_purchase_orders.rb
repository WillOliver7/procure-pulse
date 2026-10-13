class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :reference
      t.date :ordered_at
      t.string :currency
      t.string :status

      t.timestamps
    end

    add_index :purchase_orders, :reference, unique: true
  end
end
