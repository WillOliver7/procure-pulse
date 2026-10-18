require "rails_helper"

RSpec.describe ProcurementAnalyticsWorker do
  subject(:worker) { described_class.new }

  let(:analysis_run) { AnalysisRun.create! }

  describe "#perform" do
    context "when analytics succeeds" do
      let(:results) do
        {
          total_spend: 125_000,
          currency: "USD"
        }
      end

      let(:analytics) { instance_double(ProcurementAnalytics) }

      before do
        allow(AnalysisRun).to receive(:find)
          .with(analysis_run.id)
          .and_return(analysis_run)

        allow(analysis_run).to receive(:broadcast_status)
        allow(ProcurementAnalytics).to receive(:new).and_return(analytics)
        allow(analytics).to receive(:call).and_return(results)
      end

      # Keep the existing examples here.
    end

    context "when analytics fails" do
      let(:analytics) { instance_double(ProcurementAnalytics) }

      before do
        allow(AnalysisRun).to receive(:find)
          .with(analysis_run.id)
          .and_return(analysis_run)

        allow(analysis_run).to receive(:broadcast_status)
        allow(ProcurementAnalytics).to receive(:new).and_return(analytics)
        allow(analytics).to receive(:call)
          .and_raise(StandardError, "Analytics service failed")
      end

      # Keep the existing example here.
    end

    context "when the analysis run does not exist" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          worker.perform(-1)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end