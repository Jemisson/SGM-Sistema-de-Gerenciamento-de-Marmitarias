module Api
  module V1
    class MenusController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_menu, only: %i[show update destroy]

      def index
        authorize Menu

        menus = visible_menus(filtered_menus).includes(menu_items: :product).order(start_date: :desc, name: :asc)

        render_success(menus.map { |menu| serialize_menu(menu) })
      end

      def current
        authorize Menu

        menu = visible_menus(Menu.currently_active).includes(menu_items: :product).order(start_date: :desc, id: :desc).first
        raise ActiveRecord::RecordNotFound, "Couldn't find current menu" unless menu

        render_success(serialize_menu(menu))
      end

      def show
        authorize menu

        render_success(serialize_menu(menu))
      end

      def create
        menu = Menu.new(menu_params)
        authorize menu

        if menu.save
          audit_menu("menus.create", menu)
          render_created(serialize_menu(menu))
        else
          render_validation_errors(menu)
        end
      end

      def update
        authorize menu

        if menu.update(menu_params)
          audit_menu("menus.update", menu, metadata: { "changed_fields" => menu.saved_changes.keys })
          render_success(serialize_menu(menu))
        else
          render_validation_errors(menu)
        end
      end

      def destroy
        authorize menu

        menu.update!(active: false)
        audit_menu("menus.destroy", menu)

        render_success(serialize_menu(menu))
      end

      private

      attr_reader :menu

      def set_menu
        @menu = Menu.find(params[:id])
      end

      def visible_menus(scope)
        return scope if current_user&.admin? || current_user&.manager?

        scope.enabled.active
      end

      def filtered_menus
        Menu.all.then { |scope| filter_by_active(scope) }
            .then { |scope| filter_by_status(scope) }
            .then { |scope| filter_by_name(scope) }
            .then { |scope| filter_by_date(scope) }
      end

      def filter_by_active(scope)
        return scope.enabled unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_status(scope)
        return scope if filter_params[:status].blank?

        scope.where(status: filter_params[:status])
      end

      def filter_by_name(scope)
        return scope if filter_params[:name].blank?

        scope.where("name ILIKE ?", "%#{filter_params[:name]}%")
      end

      def filter_by_date(scope)
        return scope if filter_params[:date].blank?

        date = Date.iso8601(filter_params[:date])
        scope.where("start_date <= ? AND end_date >= ?", date, date)
      rescue Date::Error
        scope.none
      end

      def menu_params
        params.require(:menu).permit(
          :name,
          :start_date,
          :end_date,
          :status,
          :active,
          menu_items_attributes: [
            :id,
            :product_id,
            :available,
            :price_override,
            :_destroy
          ]
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_menu(menu)
        MenuSerializer.new(menu).as_json
      end

      def audit_menu(action, menu, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: menu,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
