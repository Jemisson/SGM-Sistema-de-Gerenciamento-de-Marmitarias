require "rails_helper"

class BaseControllerSpecRecord
  include ActiveModel::Model

  attr_accessor :name

  validates :name, presence: true
end

class BaseControllerSpecController < Api::V1::BaseController
  def success
    render_success({ message: "ok" })
  end

  def created
    render_created({ id: 1 })
  end

  def unauthorized
    render_unauthorized
  end

  def forbidden
    raise Pundit::NotAuthorizedError
  end

  def not_found
    raise ActiveRecord::RecordNotFound, "Resource not found"
  end

  def invalid
    record = BaseControllerSpecRecord.new
    record.validate

    raise ActiveRecord::RecordInvalid, record
  end

  def missing_parameter
    params.require(:name)
  end
end

RSpec.describe Api::V1::BaseController, type: :request do
  before(:all) do
    Rails.application.routes.draw do
      get "/base_controller_spec/success", to: "base_controller_spec#success"
      post "/base_controller_spec/created", to: "base_controller_spec#created"
      get "/base_controller_spec/unauthorized", to: "base_controller_spec#unauthorized"
      get "/base_controller_spec/forbidden", to: "base_controller_spec#forbidden"
      get "/base_controller_spec/not_found", to: "base_controller_spec#not_found"
      post "/base_controller_spec/invalid", to: "base_controller_spec#invalid"
      post "/base_controller_spec/missing_parameter", to: "base_controller_spec#missing_parameter"
    end
  end

  after(:all) do
    Rails.application.reload_routes!
  end

  describe "JSON responses" do
    it "renders successful responses with data" do
      get "/base_controller_spec/success"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("data" => { "message" => "ok" })
    end

    it "renders created responses with status 201" do
      post "/base_controller_spec/created"

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq("data" => { "id" => 1 })
    end
  end

  describe "error handling" do
    it "renders unauthenticated errors with status 401" do
      get "/base_controller_spec/unauthorized"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "base",
            "message" => "Authentication required."
          }
        ]
      )
    end

    it "renders authorization errors with status 403" do
      get "/base_controller_spec/forbidden"

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "base",
            "message" => "You are not authorized to perform this action."
          }
        ]
      )
    end

    it "renders not found errors with status 404" do
      get "/base_controller_spec/not_found"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "base",
            "message" => "Resource not found"
          }
        ]
      )
    end

    it "renders validation errors with status 422" do
      post "/base_controller_spec/invalid"

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "name",
            "message" => "can't be blank"
          }
        ]
      )
    end

    it "renders missing parameter errors with status 400" do
      post "/base_controller_spec/missing_parameter"

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "name",
            "message" => "param is missing or the value is empty or invalid: name"
          }
        ]
      )
    end
  end
end
