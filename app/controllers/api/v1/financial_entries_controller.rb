module Api
  module V1
    class FinancialEntriesController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_financial_entry, only: %i[show update destroy]

      def index
        authorize FinancialEntry

        entries = filtered_entries.includes(:user).order(occurred_at: :desc, id: :desc)
        paginated_entries = paginate(entries)

        render_success(
          paginated_entries.map { |entry| serialize_financial_entry(entry) },
          meta: pagination_meta(paginated_entries)
        )
      end

      def show
        authorize financial_entry

        render_success(serialize_financial_entry(financial_entry))
      end

      def create
        authorize FinancialEntry

        entry = FinancialEntryRecorder.create(user: current_user, attributes: financial_entry_params)
        audit_financial_entry("financial_entries.create", entry)

        render_created(serialize_financial_entry(entry))
      end

      def update
        authorize financial_entry

        entry = FinancialEntryRecorder.update(
          user: current_user,
          financial_entry: financial_entry,
          attributes: financial_entry_params
        )
        audit_financial_entry("financial_entries.update", entry, metadata: { "changed_fields" => entry.saved_changes.keys })

        render_success(serialize_financial_entry(entry))
      end

      def destroy
        authorize financial_entry

        entry = FinancialEntryRecorder.cancel(user: current_user, financial_entry: financial_entry, attributes: {})
        audit_financial_entry("financial_entries.destroy", entry)

        render_success(serialize_financial_entry(entry))
      end

      private

      attr_reader :financial_entry

      def set_financial_entry
        @financial_entry = FinancialEntry.find(params[:id])
      end

      def filtered_entries
        FinancialEntry.all.then { |scope| filter_by_active(scope) }
                      .then { |scope| filter_by_entry_type(scope) }
                      .then { |scope| filter_by_payment_method(scope) }
                      .then { |scope| filter_by_category(scope) }
                      .then { |scope| filter_by_start_date(scope) }
                      .then { |scope| filter_by_end_date(scope) }
      end

      def filter_by_active(scope)
        return scope.active unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_entry_type(scope)
        return scope if filter_params[:entry_type].blank?

        scope.where(entry_type: filter_params[:entry_type])
      end

      def filter_by_payment_method(scope)
        return scope if filter_params[:payment_method].blank?

        scope.where(payment_method: filter_params[:payment_method])
      end

      def filter_by_category(scope)
        return scope if filter_params[:category].blank?

        scope.where("category ILIKE ?", "%#{filter_params[:category]}%")
      end

      def filter_by_start_date(scope)
        return scope if filter_params[:start_date].blank?

        scope.where("occurred_at >= ?", Time.zone.parse(filter_params[:start_date]))
      end

      def filter_by_end_date(scope)
        return scope if filter_params[:end_date].blank?

        scope.where("occurred_at <= ?", Time.zone.parse(filter_params[:end_date]))
      end

      def financial_entry_params
        params.require(:financial_entry).permit(
          :cash_session_id,
          :entry_type,
          :category,
          :description,
          :amount,
          :payment_method,
          :occurred_at,
          :active
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_financial_entry(entry)
        FinancialEntrySerializer.new(entry).as_json
      end

      def audit_financial_entry(action, entry, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: entry,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
