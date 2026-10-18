require "rails_helper"

RSpec.describe "API V1 Authentication", type: :request do
  let(:password) { "TestPassword123!" }

  def create_user
    User.create!(
      email: "auth-test-#{SecureRandom.hex(8)}@example.com",
      password: password,
      password_confirmation: password
    )
  end

  def login_as(user)
    post "/api/v1/login",
         params: {
           user: {
             email: user.email,
             password: password
           }
         },
         as: :json

    expect(response).to have_http_status(:ok)

    response.headers["Authorization"]
  end

  describe "POST /api/v1/signup" do
    it "creates a user" do
      email = "signup-#{SecureRandom.hex(8)}@example.com"

      expect {
        post "/api/v1/signup",
             params: {
               user: {
                 email: email,
                 password: password,
                 password_confirmation: password
               }
             },
             as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body).dig("user", "email")).to eq(email)
    end

    it "rejects invalid registration data" do
      post "/api/v1/signup",
           params: {
             user: {
               email: "not-an-email",
               password: "short",
               password_confirmation: "different"
             }
           },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "POST /api/v1/login" do
    it "authenticates a user and returns a JWT" do
      user = create_user

      token = login_as(user)

      expect(token).to be_present
      expect(token).to start_with("Bearer ")
      expect(JSON.parse(response.body).dig("user", "email"))
        .to eq(user.email)
    end

    it "rejects an incorrect password" do
      user = create_user

      post "/api/v1/login",
           params: {
             user: {
               email: user.email,
               password: "WrongPassword123!"
             }
           },
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to have_key("error")
    end
  end

  describe "GET /api/v1/me" do
    it "rejects requests without a token" do
      get "/api/v1/me", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the authenticated user" do
      user = create_user
      token = login_as(user)

      get "/api/v1/me",
          headers: { "Authorization" => token },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("user", "id")).to eq(user.id)
      expect(JSON.parse(response.body).dig("user", "email"))
        .to eq(user.email)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revokes the token so it cannot be reused" do
      user = create_user
      token = login_as(user)

      expect(token).to be_present

      delete "/api/v1/logout",
             headers: { "Authorization" => token },
             as: :json

      expect(response).to have_http_status(:no_content)

      get "/api/v1/me",
          headers: { "Authorization" => token },
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
