module Api
  module V1
    class UsersController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_user, only: %i[show update destroy]

      def index
        authorize User

        users = filtered_users.order(:name)
        paginated_users = paginate(users)

        render_success(
          paginated_users.map { |user| serialize_user(user) },
          meta: pagination_meta(paginated_users)
        )
      end

      def show
        authorize user

        render_success(serialize_user(user))
      end

      def create
        user = User.new(user_params)
        authorize user

        if user.save
          audit_user("users.create", user)
          render_created(serialize_user(user))
        else
          render_validation_errors(user)
        end
      end

      def update
        authorize user

        if user.update(user_params)
          audit_user("users.update", user, metadata: { "changed_fields" => user.saved_changes.keys })
          render_success(serialize_user(user))
        else
          render_validation_errors(user)
        end
      end

      def destroy
        authorize user

        user.update!(active: false)
        audit_user("users.destroy", user)

        render_success(serialize_user(user))
      end

      private

      attr_reader :user

      def set_user
        @user = User.find(params[:id])
      end

      def filtered_users
        User.all.then { |scope| filter_by_active(scope) }
            .then { |scope| filter_by_role(scope) }
            .then { |scope| filter_by_name(scope) }
            .then { |scope| filter_by_email(scope) }
      end

      def filter_by_active(scope)
        return scope.where(active: true) unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_role(scope)
        return scope if filter_params[:role].blank?

        scope.where(role: filter_params[:role])
      end

      def filter_by_name(scope)
        return scope if filter_params[:name].blank?

        scope.where("name ILIKE ?", "%#{filter_params[:name]}%")
      end

      def filter_by_email(scope)
        return scope if filter_params[:email].blank?

        scope.where("email ILIKE ?", "%#{filter_params[:email]}%")
      end

      def user_params
        permitted_params = params.require(:user).permit(
          :name,
          :birth_date,
          :cpf,
          :phone,
          :role,
          :gender,
          :marital_status,
          :email,
          :password,
          :password_confirmation,
          :active,
          :street,
          :number,
          :neighborhood,
          :city,
          :state,
          :zip_code
        )

        if permitted_params[:password].blank?
          permitted_params.delete(:password)
          permitted_params.delete(:password_confirmation)
        end
        permitted_params
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_user(user)
        UserSerializer.new(user).as_json
      end

      def audit_user(action, user, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: user,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
