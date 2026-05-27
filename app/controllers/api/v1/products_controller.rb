module Api
  module V1
    class ProductsController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_product, only: %i[show update destroy]

      def index
        authorize Product

        products = filtered_products.includes(:category, image_attachment: :blob).order(:name)

        render_success(products.map { |product| serialize_product(product) })
      end

      def show
        authorize product

        render_success(serialize_product(product))
      end

      def create
        product = Product.new(product_params)
        authorize product

        if product.save
          audit_product("products.create", product)
          render_created(serialize_product(product))
        else
          render_validation_errors(product)
        end
      end

      def update
        authorize product

        if product.update(product_params)
          audit_product("products.update", product, metadata: { "changed_fields" => product.saved_changes.keys })
          render_success(serialize_product(product))
        else
          render_validation_errors(product)
        end
      end

      def destroy
        authorize product

        product.update!(active: false)
        audit_product("products.destroy", product)

        render_success(serialize_product(product))
      end

      private

      attr_reader :product

      def set_product
        @product = Product.find(params[:id])
      end

      def filtered_products
        Product.all.then { |scope| filter_by_active(scope) }
               .then { |scope| filter_by_name(scope) }
               .then { |scope| filter_by_code(scope) }
               .then { |scope| filter_by_category(scope) }
      end

      def filter_by_active(scope)
        return scope.active unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_name(scope)
        return scope if filter_params[:name].blank?

        scope.where("name ILIKE ?", "%#{filter_params[:name]}%")
      end

      def filter_by_code(scope)
        return scope if filter_params[:code].blank?

        scope.where(code: filter_params[:code])
      end

      def filter_by_category(scope)
        return scope if filter_params[:category_id].blank?

        scope.where(category_id: filter_params[:category_id])
      end

      def product_params
        params.require(:product).permit(
          :code,
          :name,
          :description,
          :category_id,
          :sale_price,
          :active,
          :image
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_product(product)
        ProductSerializer.new(product).as_json
      end

      def audit_product(action, product, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: product,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
