module Api
  module V1
    class SessionsController < ApplicationController
      def create
        user = User.find_for_database_authentication(
          email: params.dig(:user, :email) || params[:email]
        )

        password = params.dig(:user, :password) || params[:password]

        unless user&.valid_password?(password)
          render json: { error: "Invalid email or password" },
                 status: :unauthorized
          return
        end

        sign_in(user, store: false)

        render json: {
          user: {
            id: user.id,
            email: user.email
          }
        }, status: :ok
      end

      def destroy
        authenticate_user!

        current_user.update!(jti: SecureRandom.uuid)

        sign_out(:user)

        head :no_content
      end
    end
  end
end
