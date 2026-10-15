class ProcurementAnalyticsWorker
  include Sidekiq::Job

  sidekiq_options retry: 5

  def perform(analysis_run_id)
    analysis_run = AnalysisRun.find(analysis_run_id)

    analysis_run.update!(
      status: "processing",
      error_message: nil
    )
    analysis_run.broadcast_status

    results = ProcurementAnalytics.new.call

    analysis_run.update!(
      status: "completed",
      results: results.as_json
    )
    analysis_run.broadcast_status
  rescue StandardError => e
    if analysis_run
      analysis_run.update!(
        status: "failed",
        error_message: e.message
      )
      analysis_run.broadcast_status
    end

    raise
  end
end
