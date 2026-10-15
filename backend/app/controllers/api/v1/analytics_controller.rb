module Api
  module V1
    class AnalyticsController < ApplicationController
      def show
        render json: ProcurementAnalytics.new.call
      end
    end
  end
end
