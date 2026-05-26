module Api
  module V1
    module Auth
      class PasswordsController < BaseController
        RESET_INSTRUCTIONS_MESSAGE = "Se o e-mail estiver cadastrado, as instruções de recuperação serão enviadas.".freeze

        def create
          return render_required_field(:email) if password_request_params[:email].blank?

          user = User.find_by(email: password_request_params[:email].to_s.downcase)
          send_reset_password_instructions(user) if user.present?

          render_success({ message: RESET_INSTRUCTIONS_MESSAGE })
        end

        def update
          errors = reset_password_validation_errors
          return render json: { errors: errors }, status: :unprocessable_entity if errors.any?

          user = User.reset_password_by_token(reset_password_params)

          if user.errors.empty?
            User.revoke_jwt({}, user)
            render_success({ message: "Senha redefinida com sucesso." })
          else
            render_validation_errors(user)
          end
        end

        private

        def password_request_params
          params.require(:user).permit(:email)
        end

        def reset_password_params
          params.require(:user).permit(:reset_password_token, :password, :password_confirmation)
        end

        def send_reset_password_instructions(user)
          token = user.send(:set_reset_password_token)
          UserMailer.reset_password_instructions(user, token).deliver_later
        end

        def reset_password_validation_errors
          user_params = raw_user_params
          errors = []

          errors << error_payload(:reset_password_token, "não pode ficar em branco") if user_params[:reset_password_token].blank?
          errors << error_payload(:password, "não pode ficar em branco") if user_params[:password].blank?
          errors << error_payload(:password_confirmation, "não pode ficar em branco") if user_params[:password_confirmation].blank?

          if user_params[:password].present? && user_params[:password].length < 6
            errors << error_payload(:password, "deve ter no mínimo 6 caracteres")
          end

          if user_params[:password].present? &&
             user_params[:password_confirmation].present? &&
             user_params[:password] != user_params[:password_confirmation]
            errors << error_payload(:password_confirmation, "deve ser igual à senha")
          end

          errors
        end

        def render_required_field(field)
          render json: { errors: [error_payload(field, "não pode ficar em branco")] }, status: :unprocessable_entity
        end

        def raw_user_params
          return {} unless params[:user].respond_to?(:to_unsafe_h)

          params[:user].to_unsafe_h.symbolize_keys
        end
      end
    end
  end
end
