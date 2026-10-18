module Api
  module V1
    class AnalyticsController < ApplicationController
      before_action :authenticate_user!

      def show
        render json: ProcurementAnalytics.new.call
      end
    end
  end
end
