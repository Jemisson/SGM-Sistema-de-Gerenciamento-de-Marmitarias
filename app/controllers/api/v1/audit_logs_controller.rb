module Api
  module V1
    class AuditLogsController < Auth::BaseController
      before_action :authenticate_user_from_token!

      def index
        authorize AuditLog

        audit_logs = filtered_audit_logs.order(occurred_at: :desc, id: :desc)
        paginated_logs = paginate(audit_logs)

        render_success(
          paginated_logs.map { |audit_log| serialized_audit_log(audit_log) },
          meta: pagination_meta(paginated_logs)
        )
      end

      private

      def filtered_audit_logs
        AuditLog.includes(:user).then { |scope| filter_by_user(scope) }
                .then { |scope| filter_by_action(scope) }
                .then { |scope| filter_by_start_date(scope) }
                .then { |scope| filter_by_end_date(scope) }
      end

      def filter_by_user(scope)
        return scope if filter_params[:user_id].blank?

        scope.where(user_id: filter_params[:user_id])
      end

      def filter_by_action(scope)
        return scope if filter_params[:action].blank?

        scope.where(action: filter_params[:action])
      end

      def filter_by_start_date(scope)
        return scope if filter_params[:start_date].blank?

        scope.where("occurred_at >= ?", Time.zone.parse(filter_params[:start_date]))
      end

      def filter_by_end_date(scope)
        return scope if filter_params[:end_date].blank?

        scope.where("occurred_at <= ?", Time.zone.parse(filter_params[:end_date]))
      end

      def serialized_audit_log(audit_log)
        {
          id: audit_log.id,
          user: serialized_user(audit_log.user),
          action: audit_log.action,
          auditable_type: audit_log.auditable_type,
          auditable_id: audit_log.auditable_id,
          ip_address: audit_log.ip_address,
          user_agent: audit_log.user_agent,
          metadata: audit_log.metadata,
          occurred_at: audit_log.occurred_at&.iso8601
        }
      end

      def serialized_user(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end
    end
  end
end
