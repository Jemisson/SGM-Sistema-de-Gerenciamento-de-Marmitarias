class ApplicationController < ActionController::API
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def render_success(data = {}, status: :ok, meta: nil)
    response = { data: data }
    response[:meta] = meta if meta.present?

    render json: response, status: status
  end

  def render_error(message, status:, code: nil, details: nil)
    error = {
      code: code || Rack::Utils.status_code(status),
      message: message
    }
    error[:details] = details if details.present?

    render json: { error: error }, status: status
  end

  def render_bad_request(exception)
    render_error(
      exception.message,
      status: :bad_request,
      code: "bad_request"
    )
  end

  def render_forbidden(_exception)
    render_error(
      "You are not authorized to perform this action.",
      status: :forbidden,
      code: "forbidden"
    )
  end

  def render_not_found(exception)
    render_error(
      exception.message,
      status: :not_found,
      code: "not_found"
    )
  end

  def render_unprocessable_entity(exception)
    render_error(
      "Validation failed.",
      status: :unprocessable_entity,
      code: "unprocessable_entity",
      details: exception.record.errors.to_hash
    )
  end
end
