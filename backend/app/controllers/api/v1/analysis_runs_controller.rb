module Api
  module V1
    class AnalysisRunsController < ApplicationController
      def create
        analysis_run = AnalysisRun.create!

        job_id = ProcurementAnalyticsWorker.perform_async(
          analysis_run.id
        )

        render json: {
          id: analysis_run.id,
          status: analysis_run.status,
          job_id: job_id
        }, status: :accepted
      end

      def show
        analysis_run = AnalysisRun.find(params[:id])

        render json: {
          id: analysis_run.id,
          status: analysis_run.status,
          results: analysis_run.results,
          error_message: analysis_run.error_message
        }
      end
    end
  end
end
