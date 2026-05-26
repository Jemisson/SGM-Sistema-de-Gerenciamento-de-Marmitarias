module Api
  module V1
    module Auth
      class SessionsController < BaseController
        before_action :authenticate_user_from_token!, only: %i[destroy me]

        def create
          user = User.find_for_authentication(email: login_params[:email])

          return render_invalid_credentials if user.blank? || !user.valid_password?(login_params[:password])
          return render_inactive_user unless user.active_for_authentication?

          token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
          user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)
          response.set_header("Authorization", "Bearer #{token}")
          AuditLogger.call(user: user, action: "auth.login", auditable: user, request: request)

          render_success(
            {
              user: serialized_user(user),
              token: token
            }
          )
        end

        def destroy
          payload = Warden::JWTAuth::TokenDecoder.new.call(bearer_token)
          AuditLogger.call(user: current_user, action: "auth.logout", auditable: current_user, request: request)
          User.revoke_jwt(payload, current_user)

          render_success({ message: "Logout realizado com sucesso." })
        end

        def me
          render_success({ user: serialized_user(current_user) })
        end

        private

        def login_params
          params.require(:user).permit(:email, :password)
        end

        def serialized_user(user)
          {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            active: user.active
          }
        end

        def render_invalid_credentials
          render_error("Credenciais inválidas.", status: :unauthorized, field: :base)
        end

        def render_inactive_user
          render_error("Usuário inativo.", status: :unauthorized, field: :base)
        end
      end
    end
  end
end
