class WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  def lemonsqueezy
    payload = request.body.read
    signature = request.headers["X-Signature"]

    unless valid_signature?(payload, signature)
      head :unauthorized and return
    end

    data = JSON.parse(payload)
    event = data.dig("meta", "event_name")

    if event == "order_created" || event == "subscription_payment_success"
      email = data.dig("data", "attributes", "user_email")
      user = User.find_by(email_address: email&.downcase)
      if user
        user.update!(plan: :paid, plan_expires_at: 1.year.from_now)
      end
    end

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def valid_signature?(payload, signature)
    secret = Rails.application.credentials.dig(:ls, :webhook_secret)
    return true if secret.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  end
end
