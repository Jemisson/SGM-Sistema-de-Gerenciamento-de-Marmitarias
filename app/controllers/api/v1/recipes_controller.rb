module Api
  module V1
    class RecipesController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_recipe, only: %i[show update destroy]

      def index
        authorize Recipe

        recipes = filtered_recipes.includes(:product, recipe_items: :ingredient).order(:name)

        render_success(recipes.map { |recipe| serialize_recipe(recipe) })
      end

      def show
        authorize recipe

        render_success(serialize_recipe(recipe))
      end

      def create
        recipe = Recipe.new(recipe_params)
        authorize recipe

        if recipe.save
          audit_recipe("recipes.create", recipe)
          render_created(serialize_recipe(recipe))
        else
          render_validation_errors(recipe)
        end
      end

      def update
        authorize recipe

        if recipe.update(recipe_params)
          audit_recipe("recipes.update", recipe, metadata: { "changed_fields" => recipe.saved_changes.keys })
          render_success(serialize_recipe(recipe))
        else
          render_validation_errors(recipe)
        end
      end

      def destroy
        authorize recipe

        recipe.update!(active: false)
        audit_recipe("recipes.destroy", recipe)

        render_success(serialize_recipe(recipe))
      end

      private

      attr_reader :recipe

      def set_recipe
        @recipe = Recipe.find(params[:id])
      end

      def filtered_recipes
        Recipe.all.then { |scope| filter_by_active(scope) }
              .then { |scope| filter_by_product(scope) }
              .then { |scope| filter_by_name(scope) }
      end

      def filter_by_active(scope)
        return scope.active unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_product(scope)
        return scope if filter_params[:product_id].blank?

        scope.where(product_id: filter_params[:product_id])
      end

      def filter_by_name(scope)
        return scope if filter_params[:name].blank?

        scope.where("name ILIKE ?", "%#{filter_params[:name]}%")
      end

      def recipe_params
        params.require(:recipe).permit(
          :product_id,
          :name,
          :description,
          :active,
          recipe_items_attributes: [
            :id,
            :ingredient_id,
            :quantity,
            :unit,
            :_destroy
          ]
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_recipe(recipe)
        RecipeSerializer.new(recipe).as_json
      end

      def audit_recipe(action, recipe, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: recipe,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
