module Api
  module V1
    class IngredientsController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_ingredient, only: %i[show update destroy]

      def index
        authorize Ingredient

        ingredients = filtered_ingredients.includes(:category, :supplier).order(:name)

        render_success(ingredients.map { |ingredient| serialize_ingredient(ingredient) })
      end

      def show
        authorize ingredient

        render_success(serialize_ingredient(ingredient))
      end

      def create
        ingredient = Ingredient.new(ingredient_params)
        authorize ingredient

        if ingredient.save
          audit_ingredient("ingredients.create", ingredient)
          render_created(serialize_ingredient(ingredient))
        else
          render_validation_errors(ingredient)
        end
      end

      def update
        authorize ingredient

        if ingredient.update(ingredient_params)
          audit_ingredient("ingredients.update", ingredient, metadata: { "changed_fields" => ingredient.saved_changes.keys })
          render_success(serialize_ingredient(ingredient))
        else
          render_validation_errors(ingredient)
        end
      end

      def destroy
        authorize ingredient

        ingredient.update!(active: false)
        audit_ingredient("ingredients.destroy", ingredient)

        render_success(serialize_ingredient(ingredient))
      end

      private

      attr_reader :ingredient

      def set_ingredient
        @ingredient = Ingredient.find(params[:id])
      end

      def filtered_ingredients
        Ingredient.all.then { |scope| filter_by_active(scope) }
                   .then { |scope| filter_by_name(scope) }
                   .then { |scope| filter_by_code(scope) }
                   .then { |scope| filter_by_category(scope) }
                   .then { |scope| filter_by_supplier(scope) }
                   .then { |scope| filter_by_below_minimum_stock(scope) }
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

      def filter_by_supplier(scope)
        return scope if filter_params[:supplier_id].blank?

        scope.where(supplier_id: filter_params[:supplier_id])
      end

      def filter_by_below_minimum_stock(scope)
        return scope unless ActiveModel::Type::Boolean.new.cast(filter_params[:below_minimum_stock])

        scope.below_minimum_stock
      end

      def ingredient_params
        params.require(:ingredient).permit(
          :code,
          :name,
          :category_id,
          :supplier_id,
          :unit,
          :current_stock,
          :minimum_stock,
          :purchase_price,
          :manufacturing_date,
          :expiration_date,
          :received_at,
          :notes,
          :active
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_ingredient(ingredient)
        IngredientSerializer.new(ingredient).as_json
      end

      def audit_ingredient(action, ingredient, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: ingredient,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
