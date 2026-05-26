module Api
  module V1
    module Auth
      class BaseController < Api::V1::BaseController
        private

        def authenticate_user_from_token!
          return render_token_missing if bearer_token.blank?

          @current_user = decode_user_from_token
        rescue JWT::DecodeError,
               Warden::JWTAuth::Errors::RevokedToken,
               Warden::JWTAuth::Errors::NilUser,
               Warden::JWTAuth::Errors::WrongScope,
               Warden::JWTAuth::Errors::WrongAud
          render_token_invalid
        end

        attr_reader :current_user

        def bearer_token
          @bearer_token ||= Warden::JWTAuth::HeaderParser.from_env(request.env)
        end

        def decode_user_from_token
          payload = Warden::JWTAuth::TokenDecoder.new.call(bearer_token)
          raise Warden::JWTAuth::Errors::WrongScope, "wrong scope" unless payload["scp"] == "user"

          user = User.find_for_jwt_authentication(payload["sub"])
          raise Warden::JWTAuth::Errors::NilUser, "nil user" if user.blank?
          raise Warden::JWTAuth::Errors::RevokedToken, "revoked token" if User.jwt_revoked?(payload, user)

          user
        end

        def render_token_missing
          render_error("Token ausente.", status: :unauthorized, field: :authorization)
        end

        def render_token_invalid
          render_error("Token inválido.", status: :unauthorized, field: :authorization)
        end
      end
    end
  end
end
