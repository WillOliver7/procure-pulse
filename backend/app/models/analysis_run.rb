class AnalysisRun < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  validates :status, inclusion: { in: STATUSES }
end
