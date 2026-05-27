require "rails_helper"

RSpec.describe "Api::V1::FinancialEntries", type: :request do
  describe "GET /api/v1/financial_entries" do
    it "lists active financial entries for managers" do
      manager = create(:user, :manager)
      entry = create(:financial_entry, category: "Venda externa")
      create(:financial_entry, :inactive)

      get "/api/v1/financial_entries", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([entry.id])
    end

    it "filters entries" do
      manager = create(:user, :manager)
      included_entry = create(
        :financial_entry,
        :expense,
        category: "Energia",
        payment_method: :bank_transfer,
        occurred_at: Time.zone.local(2026, 5, 20, 12)
      )
      create(:financial_entry, :expense, category: "Agua", payment_method: :cash, occurred_at: Time.zone.local(2026, 5, 20, 12))

      get "/api/v1/financial_entries",
          params: {
            entry_type: "expense",
            payment_method: "bank_transfer",
            category: "Ener",
            start_date: "2026-05-20T00:00:00Z",
            end_date: "2026-05-21T00:00:00Z"
          },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_entry.id])
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/financial_entries", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/financial_entries/:id" do
    it "shows a financial entry for managers" do
      manager = create(:user, :manager)
      entry = create(:financial_entry)

      get "/api/v1/financial_entries/#{entry.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => entry.id,
        "entry_type" => entry.entry_type,
        "payment_method" => entry.payment_method,
        "active" => true
      )
    end
  end

  describe "POST /api/v1/financial_entries" do
    it "creates a manual financial entry and registers audit log" do
      manager = create(:user, :manager)

      expect do
        post "/api/v1/financial_entries",
             params: {
               financial_entry: {
                 entry_type: "income",
                 category: "Aporte",
                 description: "Entrada extra",
                 amount: "100.00",
                 payment_method: "pix",
                 occurred_at: Time.current.iso8601
               }
             },
             headers: authorization_header_for(manager),
             as: :json
      end.to change(FinancialEntry, :count).by(1)
        .and change(AuditLog, :count).by(1)

      entry = FinancialEntry.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => entry.id,
        "entry_type" => "income",
        "amount" => "100.0",
        "payment_method" => "pix"
      )
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "financial_entries.create",
        auditable: entry
      )
    end

    it "creates linked cash movement when cash session is informed" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session, opened_by: manager)

      expect do
        post "/api/v1/financial_entries",
             params: {
               financial_entry: {
                 cash_session_id: cash_session.id,
                 entry_type: "expense",
                 category: "Compra",
                 description: "Compra emergencial",
                 amount: "30.00",
                 payment_method: "cash",
                 occurred_at: Time.current.iso8601
               }
             },
             headers: authorization_header_for(manager),
             as: :json
      end.to change(CashMovement, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(CashMovement.last).to have_attributes(
        cash_session: cash_session,
        movement_type: "expense",
        amount: BigDecimal("30.00"),
        source: FinancialEntry.last
      )
    end

    it "returns validation errors" do
      manager = create(:user, :manager)

      post "/api/v1/financial_entries",
           params: {
             financial_entry: {
               entry_type: "expense",
               amount: "0",
               payment_method: "cash"
             }
           },
           headers: authorization_header_for(manager),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "amount",
          "message" => "must be greater than 0"
        },
        {
          "field" => "occurred_at",
          "message" => "can't be blank"
        },
        {
          "field" => "description",
          "message" => "can't be blank"
        }
      )
    end
  end

  describe "PATCH /api/v1/financial_entries/:id" do
    it "updates a manual financial entry and registers audit log" do
      manager = create(:user, :manager)
      entry = create(:financial_entry, amount: 10)

      patch "/api/v1/financial_entries/#{entry.id}",
            params: { financial_entry: { amount: "20.00", category: "Atualizada" } },
            headers: authorization_header_for(manager),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(entry.reload).to have_attributes(
        amount: BigDecimal("20.00"),
        category: "Atualizada"
      )
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "financial_entries.update",
        auditable: entry
      )
    end

    it "does not update source entries manually" do
      manager = create(:user, :manager)
      entry = create(:financial_entry, :from_sale)

      patch "/api/v1/financial_entries/#{entry.id}",
            params: { financial_entry: { amount: "20.00" } },
            headers: authorization_header_for(manager),
            as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/financial_entries/:id" do
    it "inactivates manual financial entry and registers audit log" do
      manager = create(:user, :manager)
      entry = create(:financial_entry)

      delete "/api/v1/financial_entries/#{entry.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(entry.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "financial_entries.destroy",
        auditable: entry
      )
    end

    it "does not inactivate source entries manually" do
      manager = create(:user, :manager)
      entry = create(:financial_entry, :from_sale)

      delete "/api/v1/financial_entries/#{entry.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:forbidden)
      expect(entry.reload.active).to be(true)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
