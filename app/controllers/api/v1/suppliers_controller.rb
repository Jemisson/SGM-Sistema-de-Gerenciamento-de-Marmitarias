module Api
  module V1
    class SuppliersController < Auth::BaseController
      before_action :authenticate_user_from_token!
      before_action :set_supplier, only: %i[show update destroy]

      def index
        authorize Supplier

        suppliers = filtered_suppliers.order(:name)
        paginated_suppliers = paginate(suppliers)

        render_success(
          paginated_suppliers.map { |supplier| serialize_supplier(supplier) },
          meta: pagination_meta(paginated_suppliers)
        )
      end

      def show
        authorize supplier

        render_success(serialize_supplier(supplier))
      end

      def create
        supplier = Supplier.new(supplier_params)
        authorize supplier

        if supplier.save
          audit_supplier("suppliers.create", supplier)
          render_created(serialize_supplier(supplier))
        else
          render_validation_errors(supplier)
        end
      end

      def update
        authorize supplier

        if supplier.update(supplier_params)
          audit_supplier("suppliers.update", supplier, metadata: { "changed_fields" => supplier.saved_changes.keys })
          render_success(serialize_supplier(supplier))
        else
          render_validation_errors(supplier)
        end
      end

      def destroy
        authorize supplier

        supplier.update!(active: false)
        audit_supplier("suppliers.destroy", supplier)

        render_success(serialize_supplier(supplier))
      end

      private

      attr_reader :supplier

      def set_supplier
        @supplier = Supplier.find(params[:id])
      end

      def filtered_suppliers
        Supplier.all.then { |scope| filter_by_active(scope) }
                    .then { |scope| filter_by_name(scope) }
                    .then { |scope| filter_by_cnpj(scope) }
      end

      def filter_by_active(scope)
        return scope.active unless filter_params.key?(:active)

        scope.where(active: ActiveModel::Type::Boolean.new.cast(filter_params[:active]))
      end

      def filter_by_name(scope)
        return scope if filter_params[:name].blank?

        scope.where("name ILIKE ?", "%#{filter_params[:name]}%")
      end

      def filter_by_cnpj(scope)
        return scope if filter_params[:cnpj].blank?

        scope.where(cnpj: filter_params[:cnpj])
      end

      def supplier_params
        params.require(:supplier).permit(
          :name,
          :cnpj,
          :phone,
          :email,
          :street,
          :number,
          :neighborhood,
          :city,
          :state,
          :zip_code,
          :active
        )
      end

      def filter_params
        request.query_parameters.symbolize_keys
      end

      def serialize_supplier(supplier)
        SupplierSerializer.new(supplier).as_json
      end

      def audit_supplier(action, supplier, metadata: {})
        AuditLogger.call(
          user: current_user,
          action: action,
          auditable: supplier,
          request: request,
          metadata: metadata
        )
      end
    end
  end
end
