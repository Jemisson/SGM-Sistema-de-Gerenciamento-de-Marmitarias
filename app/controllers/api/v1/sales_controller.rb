module Api
  module V1
    class SalesController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_sale, only: %i[show cancel]

      def index
        authorize Sale

        sales = visible_sales.includes(:user, sale_items: :product).order(sold_at: :desc, id: :desc)
        paginated_sales = paginate(sales)

        render_success(
          paginated_sales.map { |sale| serialize_sale(sale) },
          meta: pagination_meta(paginated_sales)
        )
      end

      def show
        authorize sale

        render_success(serialize_sale(sale))
      end

      def create
        authorize Sale

        sale = SaleCreator.call(
          user: current_user,
          cash_session_id: sale_params[:cash_session_id],
          payment_method: sale_params[:payment_method],
          items: sale_params[:sale_items_attributes],
          sold_at: sale_params[:sold_at]
        )
        audit_sale("sales.create", sale)

        render_created(serialize_sale(sale))
      end

      def cancel
        authorize sale

        if sale.canceled?
          sale.errors.add(:status, "is already canceled")
          render_validation_errors(sale)
          return
        end

        # TODO: evaluate safe stock and cash reversal rules before restoring inventory on cancellation.
        sale.update!(status: :canceled)
        audit_sale("sales.cancel", sale)

        render_success(serialize_sale(sale))
      end

      private

      attr_reader :sale

      def set_sale
        @sale = visible_sales.find(params[:id])
      end

      def visible_sales
        return Sale.all if current_user&.admin? || current_user&.manager?

        current_user.sales
      end

      def sale_params
        params.require(:sale).permit(
          :cash_session_id,
          :payment_method,
          :sold_at,
          sale_items_attributes: [
            :product_id,
            :quantity
          ]
        )
      end

      def serialize_sale(sale)
        SaleSerializer.new(sale).as_json
      end

      def audit_sale(action, sale)
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: sale,
          request: request,
          metadata: {
            "cash_session_id" => sale.cash_session_id,
            "total_amount" => sale.total_amount.to_s,
            "payment_method" => sale.payment_method,
            "status" => sale.status
          }
        )
      end
    end
  end
end
