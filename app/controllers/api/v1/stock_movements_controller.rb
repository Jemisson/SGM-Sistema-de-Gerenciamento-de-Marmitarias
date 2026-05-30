module Api
  module V1
    class StockMovementsController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_stock_movement, only: :show

      def index
        authorize StockMovement

        stock_movements = filtered_stock_movements.includes(:ingredient, :user).order(occurred_at: :desc, id: :desc)
        paginated_stock_movements = paginate(stock_movements)

        render_success(
          paginated_stock_movements.map { |stock_movement| serialize_stock_movement(stock_movement) },
          meta: pagination_meta(paginated_stock_movements)
        )
      end

      def show
        authorize stock_movement

        render_success(serialize_stock_movement(stock_movement))
      end

      def create
        authorize StockMovement

        movement = StockMovementCreator.call(
          user: current_user,
          ingredient: ingredient,
          movement_type: stock_movement_params[:movement_type],
          quantity: stock_movement_params[:quantity],
          unit_cost: stock_movement_params[:unit_cost],
          reason: stock_movement_params[:reason],
          source_type: stock_movement_params[:source_type],
          source_id: stock_movement_params[:source_id],
          occurred_at: stock_movement_params[:occurred_at]
        )
        audit_stock_movement("stock_movements.create", movement)

        render_created(serialize_stock_movement(movement))
      end

      private

      attr_reader :stock_movement

      def set_stock_movement
        @stock_movement = StockMovement.find(params[:id])
      end

      def ingredient
        @ingredient ||= Ingredient.find(stock_movement_params[:ingredient_id])
      end

      def filtered_stock_movements
        StockMovement.all.then { |scope| filter_by_ingredient(scope) }
                     .then { |scope| filter_by_movement_type(scope) }
                     .then { |scope| filter_by_start_date(scope) }
                     .then { |scope| filter_by_end_date(scope) }
      end

      def filter_by_ingredient(scope)
        return scope if filter_params[:ingredient_id].blank?

        scope.where(ingredient_id: filter_params[:ingredient_id])
      end

      def filter_by_movement_type(scope)
        return scope if filter_params[:movement_type].blank?

        scope.where(movement_type: filter_params[:movement_type])
      end

      def filter_by_start_date(scope)
        return scope if filter_params[:start_date].blank?

        scope.where("occurred_at >= ?", Time.zone.parse(filter_params[:start_date]))
      end

      def filter_by_end_date(scope)
        return scope if filter_params[:end_date].blank?

        scope.where("occurred_at <= ?", Time.zone.parse(filter_params[:end_date]))
      end

      def stock_movement_params
        params.require(:stock_movement).permit(
          :ingredient_id,
          :movement_type,
          :quantity,
          :unit_cost,
          :reason,
          :source_type,
          :source_id,
          :occurred_at
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_stock_movement(stock_movement)
        StockMovementSerializer.new(stock_movement).as_json
      end

      def audit_stock_movement(action, stock_movement)
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: stock_movement,
          request: request,
          metadata: {
            "ingredient_id" => stock_movement.ingredient_id,
            "movement_type" => stock_movement.movement_type,
            "quantity" => stock_movement.quantity.to_s
          }
        )
      end
    end
  end
end
