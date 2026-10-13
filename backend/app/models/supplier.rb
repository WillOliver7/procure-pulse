class Supplier < ApplicationRecord
  has_many :purchase_orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :country, presence: true
end
