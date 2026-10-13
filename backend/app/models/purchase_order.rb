class PurchaseOrder < ApplicationRecord
  belongs_to :supplier
  has_many :purchase_order_items, dependent: :destroy

  validates :reference, presence: true, uniqueness: true
  validates :ordered_at, :currency, :status, presence: true
end
