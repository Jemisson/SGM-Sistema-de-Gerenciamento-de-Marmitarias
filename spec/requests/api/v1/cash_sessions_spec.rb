require "rails_helper"

RSpec.describe "Api::V1::CashSessions", type: :request do
  describe "GET /api/v1/cash_sessions" do
    it "lists cash sessions for managers" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session)

      get "/api/v1/cash_sessions", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([cash_session.id])
    end

    it "lists only own cash sessions for cashiers" do
      cashier = create(:user, :cashier)
      own_session = create(:cash_session, opened_by: cashier)
      create(:cash_session)

      get "/api/v1/cash_sessions", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([own_session.id])
    end

    it "forbids admins" do
      admin = create(:user, :admin)

      get "/api/v1/cash_sessions", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/cash_sessions"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/cash_sessions/current" do
    it "returns the current opened cash session" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session, opened_by: cashier)

      get "/api/v1/cash_sessions/current", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(cash_session.id)
    end

    it "returns 404 when there is no current cash session" do
      cashier = create(:user, :cashier)

      get "/api/v1/cash_sessions/current", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/cash_sessions/:id" do
    it "shows a cash session" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session, opened_by: cashier)

      get "/api/v1/cash_sessions/#{cash_session.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => cash_session.id,
        "opening_amount" => cash_session.opening_amount.to_s,
        "status" => "opened"
      )
    end

    it "does not show another cashier cash session" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session)

      get "/api/v1/cash_sessions/#{cash_session.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/cash_sessions/open" do
    it "opens a cash session for cashiers and registers audit log" do
      cashier = create(:user, :cashier)

      expect do
        post "/api/v1/cash_sessions/open",
             params: { cash_session: { opening_amount: "100.00", notes: "Inicio do turno" } },
             headers: authorization_header_for(cashier),
             as: :json
      end.to change(CashSession, :count).by(1)
        .and change(CashMovement, :count).by(1)
        .and change(AuditLog, :count).by(1)

      cash_session = CashSession.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => cash_session.id,
        "opening_amount" => "100.0",
        "status" => "opened"
      )
      expect(AuditLog.last).to have_attributes(
        user: cashier,
        action: "cash_sessions.open",
        auditable: cash_session
      )
    end

    it "opens a cash session for managers" do
      manager = create(:user, :manager)

      post "/api/v1/cash_sessions/open",
           params: { cash_session: { opening_amount: "50.00" } },
           headers: authorization_header_for(manager),
           as: :json

      expect(response).to have_http_status(:created)
    end

    it "does not allow the same user to open another cash session" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)

      post "/api/v1/cash_sessions/open",
           params: { cash_session: { opening_amount: "20.00" } },
           headers: authorization_header_for(cashier),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "base",
          "message" => "user already has an opened cash session"
        }
      )
    end

    it "validates opening amount" do
      cashier = create(:user, :cashier)

      post "/api/v1/cash_sessions/open",
           params: { cash_session: { opening_amount: "-1.00" } },
           headers: authorization_header_for(cashier),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "opening_amount",
          "message" => "must be greater than or equal to 0"
        }
      )
    end

    it "forbids admins" do
      admin = create(:user, :admin)

      post "/api/v1/cash_sessions/open",
           params: { cash_session: { opening_amount: "100.00" } },
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/cash_sessions/:id/close" do
    it "closes a cash session for cashiers and registers audit log" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session, opened_by: cashier, opening_amount: 100)
      create(:cash_movement, cash_session: cash_session, user: cashier, movement_type: :income, amount: 25)
      create(:cash_movement, cash_session: cash_session, user: cashier, movement_type: :expense, amount: 5)

      expect do
        patch "/api/v1/cash_sessions/#{cash_session.id}/close",
              params: { cash_session: { closing_amount: "130.00", notes: "Fechado" } },
              headers: authorization_header_for(cashier),
              as: :json
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(cash_session.reload).to have_attributes(
        status: "closed",
        closing_amount: BigDecimal("130.00"),
        expected_amount: BigDecimal("120.00"),
        difference_amount: BigDecimal("10.00")
      )
      expect(AuditLog.last).to have_attributes(
        user: cashier,
        action: "cash_sessions.close",
        auditable: cash_session
      )
    end

    it "allows managers to close any opened cash session" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session)

      patch "/api/v1/cash_sessions/#{cash_session.id}/close",
            params: { cash_session: { closing_amount: "100.00" } },
            headers: authorization_header_for(manager),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(cash_session.reload).to be_closed
    end

    it "requires closing amount" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session, opened_by: cashier)

      patch "/api/v1/cash_sessions/#{cash_session.id}/close",
            params: { cash_session: { closing_amount: nil } },
            headers: authorization_header_for(cashier),
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "closing_amount",
          "message" => "can't be blank"
        }
      )
    end

    it "does not close an already closed cash session" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session, :closed)

      patch "/api/v1/cash_sessions/#{cash_session.id}/close",
            params: { cash_session: { closing_amount: "100.00" } },
            headers: authorization_header_for(manager),
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "status",
          "message" => "must be opened"
        }
      )
    end

    it "does not close another cashier cash session" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session)

      patch "/api/v1/cash_sessions/#{cash_session.id}/close",
            params: { cash_session: { closing_amount: "100.00" } },
            headers: authorization_header_for(cashier),
            as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
