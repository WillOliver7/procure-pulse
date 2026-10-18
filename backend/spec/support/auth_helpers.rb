module AuthHelpers
  def create_authenticated_user
    password = "TestPassword123!"

    user = User.create!(
      email: "spec-#{SecureRandom.hex(8)}@example.com",
      password: password,
      password_confirmation: password
    )

    post "/api/v1/login",
         params: {
           user: {
             email: user.email,
             password: password
           }
         },
         as: :json

    raise "Login failed: #{response.status} #{response.body}" unless response.successful?

    token = response.headers["Authorization"]
    raise "Login did not return a JWT" if token.blank?

    { user: user, headers: { "Authorization" => token } }
  end
end