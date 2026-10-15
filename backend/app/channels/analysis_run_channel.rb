class AnalysisRunChannel < ApplicationCable::Channel
  def subscribed
    analysis_run = AnalysisRun.find_by(id: params[:id])

    if analysis_run
      stream_for analysis_run
    else
      reject
    end
  end
end
