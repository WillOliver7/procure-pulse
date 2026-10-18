require "rails_helper"

RSpec.describe "API V1 Analysis Runs", type: :request do
  describe "POST /api/v1/analysis_runs" do
    it "requires authentication" do
      post "/api/v1/analysis_runs", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "creates an analysis and enqueues a job" do
      auth = create_authenticated_user

      expect {
        post "/api/v1/analysis_runs", headers: auth[:headers]
      }.to change(AnalysisRun, :count).by(1)

      expect(response).to have_http_status(:accepted)

      body = JSON.parse(response.body)

      expect(body["id"]).to be_present
      expect(body["status"]).to eq("pending")
      expect(body["job_id"]).to be_present
    end
  end

  describe "GET /api/v1/analysis_runs/:id" do
    it "requires authentication" do
      run = AnalysisRun.create!

      get "/api/v1/analysis_runs/#{run.id}", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the analysis status and results" do
      auth = create_authenticated_user

      run = AnalysisRun.create!(
        status: "completed",
        results: { currency: "USD", order_count: 2 }
      )

      get "/api/v1/analysis_runs/#{run.id}", headers: auth[:headers]

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["id"]).to eq(run.id)
      expect(body["status"]).to eq("completed")
      expect(body["results"]["currency"]).to eq("USD")
      expect(body["results"]["order_count"]).to eq(2)
    end

    it "returns not found for a nonexistent analysis" do
      auth = create_authenticated_user

      get "/api/v1/analysis_runs/999999", headers: auth[:headers]

      expect(response).to have_http_status(:not_found)
    end
  end
end
