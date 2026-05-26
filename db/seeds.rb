# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

admin = User.find_or_initialize_by(email: "admin@sgm.test")

admin.assign_attributes(
  name: "Administrador SGM",
  cpf: "00000000000",
  phone: "44999999999",
  role: :admin,
  gender: "not_informed",
  marital_status: "not_informed",
  active: true,
  street: "Avenida Colombo",
  number: "5790",
  neighborhood: "Zona 7",
  city: "Maringa",
  state: "PR",
  zip_code: "87020900",
  password: ENV.fetch("DEFAULT_ADMIN_PASSWORD", "password123")
)

admin.save!

puts "Usuário administrador padrão criado/atualizado: #{admin.email}"
