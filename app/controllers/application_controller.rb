class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  protected

  def render_success(data = {}, status: :ok, meta: nil)
    response = { data: data }
    response[:meta] = meta if meta.present?

    render json: response, status: status
  end

  def render_created(data = {}, meta: nil)
    render_success(data, status: :created, meta: meta)
  end

  def render_error(message, status:, field: :base)
    render json: { errors: [error_payload(field, message)] }, status: status
  end

  def render_validation_errors(record)
    render json: { errors: validation_error_payload(record.errors) }, status: :unprocessable_entity
  end

  def render_unauthorized(message = "Authentication required.")
    render_error(message, status: :unauthorized)
  end

  private

  def error_payload(field, message)
    {
      field: field.to_s,
      message: message
    }
  end

  def validation_error_payload(errors)
    errors.map do |error|
      error_payload(error.attribute, error.message)
    end
  end

  def render_bad_request(exception)
    render_error(
      exception.message,
      status: :bad_request,
      field: exception.param
    )
  end

  def render_forbidden(_exception)
    render_error(
      "You are not authorized to perform this action.",
      status: :forbidden
    )
  end

  def render_not_found(exception)
    render_error(
      exception.message,
      status: :not_found
    )
  end

  def render_unprocessable_entity(exception)
    render_validation_errors(exception.record)
  end
end
