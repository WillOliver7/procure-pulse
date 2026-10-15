class AnalysisRun < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  def broadcast_status
    AnalysisRunChannel.broadcast_to(
      self,
      {
        id: id,
        status: status,
        results: results,
        error_message: error_message
      }
    )
  end
end
