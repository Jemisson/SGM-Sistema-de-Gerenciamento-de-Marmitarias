class SupplierSerializer
  def initialize(supplier)
    @supplier = supplier
  end

  def as_json(*)
    {
      id: supplier.id,
      name: supplier.name,
      cnpj: supplier.cnpj,
      phone: supplier.phone,
      email: supplier.email,
      street: supplier.street,
      number: supplier.number,
      neighborhood: supplier.neighborhood,
      city: supplier.city,
      state: supplier.state,
      zip_code: supplier.zip_code,
      active: supplier.active,
      created_at: supplier.created_at&.iso8601,
      updated_at: supplier.updated_at&.iso8601
    }
  end

  private

  attr_reader :supplier
end
