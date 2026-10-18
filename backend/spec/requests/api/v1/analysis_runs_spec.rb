require "rails_helper"

RSpec.describe "API V1 Analysis Runs", type: :request do
  describe "POST /api/v1/analysis_runs" do
    it "creates an analysis and enqueues a job" do
      auth = create_authenticated_user

      expect {
        post "/api/v1/analysis_runs", headers: auth[:headers]
      }.to change(AnalysisRun, :count).by(1)

      expect(response).to have_http_status(:accepted)

      body = JSON.parse(response.body)

      expect(body["status"]).to eq("pending")
      expect(body["job_id"]).to be_present
    end
  end

  describe "GET /api/v1/analysis_runs/:id" do
    it "returns the analysis status and results" do
      auth = create_authenticated_user

      run = AnalysisRun.create!(
        status: "completed",
        results: { currency: "USD", order_count: 2 }
      )

      get "/api/v1/analysis_runs/#{run.id}", headers: auth[:headers]

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["status"]).to eq("completed")
      expect(body["results"]["currency"]).to eq("USD")
      expect(body["results"]["order_count"]).to eq(2)
    end
  end
end
