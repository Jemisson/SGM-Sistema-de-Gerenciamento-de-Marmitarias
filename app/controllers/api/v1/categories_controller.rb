module Api
  module V1
    class CategoriesController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_category, only: %i[show update destroy]

      def index
        authorize Category

        categories = Category.active.order(:name)

        render_success(categories.map { |category| serialize_category(category) })
      end

      def show
        authorize category

        render_success(serialize_category(category))
      end

      def create
        category = Category.new(category_params)
        authorize category

        if category.save
          audit_category("categories.create", category)
          render_created(serialize_category(category))
        else
          render_validation_errors(category)
        end
      end

      def update
        authorize category

        if category.update(category_params)
          audit_category("categories.update", category, metadata: { "changed_fields" => category.saved_changes.keys })
          render_success(serialize_category(category))
        else
          render_validation_errors(category)
        end
      end

      def destroy
        authorize category

        category.update!(active: false)
        audit_category("categories.destroy", category)

        render_success(serialize_category(category))
      end

      private

      attr_reader :category

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:name, :description, :active)
      end

      def serialize_category(category)
        CategorySerializer.new(category).as_json
      end

      def audit_category(action, category, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: category,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
