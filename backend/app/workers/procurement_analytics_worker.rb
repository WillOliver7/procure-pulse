class ProcurementAnalyticsWorker
  include Sidekiq::Job

  sidekiq_options retry: 5

  def perform(analysis_run_id)
    analysis_run = AnalysisRun.find(analysis_run_id)

    analysis_run.update!(
      status: "processing",
      error_message: nil
    )

    results = ProcurementAnalytics.new.call

    analysis_run.update!(
      status: "completed",
      results: results.as_json
    )
  rescue StandardError => e
    if analysis_run
      analysis_run.update!(
        status: "failed",
        error_message: e.message
      )
    end

    raise
  end
end
