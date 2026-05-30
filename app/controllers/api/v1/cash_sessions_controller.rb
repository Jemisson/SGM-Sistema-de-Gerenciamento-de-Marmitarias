module Api
  module V1
    class CashSessionsController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_cash_session, only: %i[show close]

      def index
        authorize CashSession

        cash_sessions = visible_cash_sessions.includes(:opened_by, :closed_by, cash_movements: :user).order(opened_at: :desc, id: :desc)
        paginated_cash_sessions = paginate(cash_sessions)

        render_success(
          paginated_cash_sessions.map { |cash_session| serialize_cash_session(cash_session) },
          meta: pagination_meta(paginated_cash_sessions)
        )
      end

      def current
        authorize CashSession

        cash_session = visible_cash_sessions.opened.includes(:opened_by, :closed_by, cash_movements: :user).order(opened_at: :desc, id: :desc).first
        raise ActiveRecord::RecordNotFound, "Couldn't find current cash session" unless cash_session

        render_success(serialize_cash_session(cash_session))
      end

      def show
        authorize cash_session

        render_success(serialize_cash_session(cash_session))
      end

      def open
        authorize CashSession

        cash_session = CashSessionOpener.call(
          user: current_user,
          opening_amount: open_params[:opening_amount],
          notes: open_params[:notes],
          opened_at: open_params[:opened_at]
        )
        audit_cash_session("cash_sessions.open", cash_session)

        render_created(serialize_cash_session(cash_session))
      end

      def close
        authorize cash_session

        closed_cash_session = CashSessionCloser.call(
          cash_session: cash_session,
          user: current_user,
          closing_amount: close_params[:closing_amount],
          notes: close_params[:notes],
          closed_at: close_params[:closed_at]
        )
        audit_cash_session("cash_sessions.close", closed_cash_session)

        render_success(serialize_cash_session(closed_cash_session))
      end

      private

      attr_reader :cash_session

      def set_cash_session
        @cash_session = visible_cash_sessions.find(params[:id])
      end

      def visible_cash_sessions
        return CashSession.all if current_user&.admin? || current_user&.manager?

        current_user.opened_cash_sessions
      end

      def open_params
        params.require(:cash_session).permit(:opening_amount, :opened_at, :notes)
      end

      def close_params
        params.require(:cash_session).permit(:closing_amount, :closed_at, :notes)
      end

      def serialize_cash_session(cash_session)
        CashSessionSerializer.new(cash_session).as_json
      end

      def audit_cash_session(action, cash_session)
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: cash_session,
          request: request,
          metadata: {
            "status" => cash_session.status,
            "opening_amount" => cash_session.opening_amount.to_s,
            "closing_amount" => cash_session.closing_amount&.to_s,
            "expected_amount" => cash_session.expected_amount&.to_s,
            "difference_amount" => cash_session.difference_amount&.to_s
          }
        )
      end
    end
  end
end
