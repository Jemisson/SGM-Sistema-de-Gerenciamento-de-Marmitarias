class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: user.id,
      name: user.name,
      birth_date: user.birth_date&.iso8601,
      cpf: user.cpf,
      phone: user.phone,
      role: user.role,
      gender: user.gender,
      marital_status: user.marital_status,
      email: user.email,
      active: user.active,
      street: user.street,
      number: user.number,
      neighborhood: user.neighborhood,
      city: user.city,
      state: user.state,
      zip_code: user.zip_code,
      created_at: user.created_at&.iso8601,
      updated_at: user.updated_at&.iso8601
    }
  end

  private

  attr_reader :user
end
