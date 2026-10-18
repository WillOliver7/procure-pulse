module Api
  module V1
    class PurchaseOrdersController < ApplicationController
      before_action :authenticate_user!

      def index
        orders = PurchaseOrder
          .includes(:supplier, :purchase_order_items)
          .order(ordered_at: :desc)

        render json: orders.as_json(
          include: [:supplier, :purchase_order_items]
        )
      end

      def show
        order = PurchaseOrder
          .includes(:supplier, :purchase_order_items)
          .find(params[:id])

        render json: order.as_json(
          include: [:supplier, :purchase_order_items]
        )
      end
    end
  end
end