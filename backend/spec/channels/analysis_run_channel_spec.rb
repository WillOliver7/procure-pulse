require "rails_helper"

RSpec.describe AnalysisRunChannel, type: :channel do
  let(:analysis_run) { AnalysisRun.create! }

  before do
    stub_connection
  end

  it "confirms the subscription and streams updates for an existing analysis run" do
    subscribe(id: analysis_run.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(analysis_run)
  end

  it "rejects the subscription when the analysis run does not exist" do
    subscribe(id: -1)

    expect(subscription).to be_rejected
  end
end
