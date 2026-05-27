module Api
  module V1
    class CategoriesController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_category, only: %i[show update destroy]

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100

      def index
        authorize Category

        categories = filtered_categories.order(:name)
        paginated_categories = categories.offset(offset).limit(per_page)

        render_success(
          paginated_categories.map { |category| serialize_category(category) },
          meta: pagination_meta(categories.count)
        )
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

      def filtered_categories
        Category.all.then { |scope| filter_by_active(scope) }
                .then { |scope| filter_by_name(scope) }
      end

      def filter_by_active(scope)
        return scope.active unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_name(scope)
        return scope if filter_params[:name].blank?

        scope.where("name ILIKE ?", "%#{filter_params[:name]}%")
      end

      def category_params
        params.require(:category).permit(:name, :description, :active)
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def page
        [filter_params.fetch(:page, 1).to_i, 1].max
      end

      def per_page
        requested_per_page = filter_params.fetch(:per_page, DEFAULT_PER_PAGE).to_i

        requested_per_page.clamp(1, MAX_PER_PAGE)
      end

      def offset
        (page - 1) * per_page
      end

      def pagination_meta(total_count)
        {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }
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
