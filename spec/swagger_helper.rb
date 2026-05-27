# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "SGM - Sistema de Gerenciamento para Marmitaria API",
        version: "v1"
      },
      paths: {},
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          user: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              email: { type: :string },
              role: { type: :string, enum: %w[admin manager cashier] },
              active: { type: :boolean }
            }
          },
          error_response: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    field: { type: :string },
                    message: { type: :string }
                  }
                }
              }
            }
          },
          message_response: {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  message: { type: :string }
                }
              }
            }
          },
          audit_log: {
            type: :object,
            properties: {
              id: { type: :integer },
              user: { "$ref" => "#/components/schemas/user" },
              action: { type: :string },
              auditable_type: { type: :string, nullable: true },
              auditable_id: { type: :integer, nullable: true },
              ip_address: { type: :string, nullable: true },
              user_agent: { type: :string, nullable: true },
              metadata: { type: :object },
              occurred_at: { type: :string, format: "date-time" }
            }
          },
          category: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              active: { type: :boolean },
              created_at: { type: :string, format: "date-time", nullable: true },
              updated_at: { type: :string, format: "date-time", nullable: true }
            }
          },
          category_payload: {
            type: :object,
            properties: {
              category: {
                type: :object,
                properties: {
                  name: { type: :string, example: "Marmitas" },
                  description: { type: :string, example: "Categorias de marmitas prontas" },
                  active: { type: :boolean, example: true }
                },
                required: %w[name]
              }
            },
            required: %w[category]
          },
          supplier: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              cnpj: { type: :string },
              phone: { type: :string, nullable: true },
              email: { type: :string, nullable: true },
              street: { type: :string, nullable: true },
              number: { type: :string, nullable: true },
              neighborhood: { type: :string, nullable: true },
              city: { type: :string, nullable: true },
              state: { type: :string, nullable: true },
              zip_code: { type: :string, nullable: true },
              active: { type: :boolean },
              created_at: { type: :string, format: "date-time", nullable: true },
              updated_at: { type: :string, format: "date-time", nullable: true }
            }
          },
          supplier_payload: {
            type: :object,
            properties: {
              supplier: {
                type: :object,
                properties: {
                  name: { type: :string, example: "Fornecedor Central" },
                  cnpj: { type: :string, example: "12345678000199" },
                  phone: { type: :string, example: "44999999999" },
                  email: { type: :string, example: "central@sgm.test" },
                  street: { type: :string, example: "Avenida Colombo" },
                  number: { type: :string, example: "5790" },
                  neighborhood: { type: :string, example: "Zona 7" },
                  city: { type: :string, example: "Maringa" },
                  state: { type: :string, example: "PR" },
                  zip_code: { type: :string, example: "87020900" },
                  active: { type: :boolean, example: true }
                },
                required: %w[name cnpj]
              }
            },
            required: %w[supplier]
          },
          ingredient: {
            type: :object,
            properties: {
              id: { type: :integer },
              code: { type: :string },
              name: { type: :string },
              category: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string, nullable: true }
                }
              },
              supplier: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string, nullable: true }
                }
              },
              unit: { type: :string },
              current_stock: { type: :string },
              minimum_stock: { type: :string },
              purchase_price: { type: :string, nullable: true },
              manufacturing_date: { type: :string, format: "date", nullable: true },
              expiration_date: { type: :string, format: "date", nullable: true },
              received_at: { type: :string, format: "date", nullable: true },
              notes: { type: :string, nullable: true },
              active: { type: :boolean },
              created_at: { type: :string, format: "date-time", nullable: true },
              updated_at: { type: :string, format: "date-time", nullable: true }
            }
          },
          ingredient_payload: {
            type: :object,
            properties: {
              ingredient: {
                type: :object,
                properties: {
                  code: { type: :string, example: "INS001" },
                  name: { type: :string, example: "Arroz" },
                  category_id: { type: :integer },
                  supplier_id: { type: :integer },
                  unit: { type: :string, example: "kg" },
                  current_stock: { type: :string, example: "10.500" },
                  minimum_stock: { type: :string, example: "2.000" },
                  purchase_price: { type: :string, example: "15.90" },
                  manufacturing_date: { type: :string, format: "date" },
                  expiration_date: { type: :string, format: "date" },
                  received_at: { type: :string, format: "date" },
                  notes: { type: :string, example: "Insumo usado na produção" },
                  active: { type: :boolean, example: true }
                },
                required: %w[code name category_id supplier_id unit]
              }
            },
            required: %w[ingredient]
          },
          pagination_meta: {
            type: :object,
            properties: {
              page: { type: :integer },
              per_page: { type: :integer },
              total_count: { type: :integer },
              total_pages: { type: :integer }
            }
          }
        }
      },
      servers: [
        {
          url: "http://{defaultHost}",
          variables: {
            defaultHost: {
              default: "localhost:3000"
            }
          }
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
