require "test_helper"
require "openssl"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  def post_webhook(body, signature: nil)
    post webhooks_lemonsqueezy_path,
      params: body,
      headers: { "Content-Type" => "application/json", "X-Signature" => signature.to_s }
  end

  def order_payload(email:, event: "order_created")
    JSON.generate({ meta: { event_name: event }, data: { attributes: { user_email: email } } })
  end

  test "POST lemonsqueezy without webhook secret always returns ok" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    post_webhook(order_payload(email: "alice@example.com"))
    assert_response :ok
  end

  test "POST lemonsqueezy with wrong signature returns unauthorized" do
    ENV["LEMONSQUEEZY_WEBHOOK_SECRET"] = "secret"
    post_webhook(order_payload(email: "alice@example.com"), signature: "badsignature")
    assert_response :unauthorized
  ensure
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
  end

  test "POST lemonsqueezy order_created upgrades matching user plan" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    alice = users(:alice)
    assert alice.free?
    post_webhook(order_payload(email: "alice@example.com"))
    assert_response :ok
    assert alice.reload.paid?
    assert alice.reload.plan_expires_at > Time.current
  end

  test "POST lemonsqueezy subscription_payment_success upgrades user plan" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    alice = users(:alice)
    post_webhook(order_payload(email: "alice@example.com", event: "subscription_payment_success"))
    assert_response :ok
    assert alice.reload.paid?
  end

  test "POST lemonsqueezy with unknown event returns ok without changing user" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    alice = users(:alice)
    post_webhook(order_payload(email: "alice@example.com", event: "refund_created"))
    assert_response :ok
    assert alice.reload.free?
  end

  test "POST lemonsqueezy with invalid JSON returns bad_request" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    post_webhook("not valid json {{{")
    assert_response :bad_request
  end

  test "POST lemonsqueezy with unknown email does not raise" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    post_webhook(order_payload(email: "ghost@example.com"))
    assert_response :ok
  end

  test "POST lemonsqueezy email match is case-insensitive" do
    ENV.delete("LEMONSQUEEZY_WEBHOOK_SECRET")
    alice = users(:alice)
    post_webhook(order_payload(email: "ALICE@EXAMPLE.COM"))
    assert_response :ok
    assert alice.reload.paid?
  end
end
