require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders registration form" do
    get new_registration_path
    assert_response :success
  end

  test "POST create with valid params creates user and redirects" do
    assert_difference "User.count", 1 do
      post registrations_path, params: {
        user: { email_address: "new@example.com", password: "supersecret", password_confirmation: "supersecret" }
      }
    end
    assert_redirected_to new_session_path
    assert_includes flash[:notice], "Check your email"
  end

  test "POST create enqueues confirmation email" do
    assert_emails 1 do
      post registrations_path, params: {
        user: { email_address: "new@example.com", password: "supersecret", password_confirmation: "supersecret" }
      }
    end
  end

  test "POST create with invalid params re-renders form" do
    post registrations_path, params: {
      user: { email_address: "", password: "supersecret", password_confirmation: "supersecret" }
    }
    assert_response :unprocessable_entity
  end

  test "POST create with duplicate email re-renders form" do
    post registrations_path, params: {
      user: { email_address: "alice@example.com", password: "supersecret", password_confirmation: "supersecret" }
    }
    assert_response :unprocessable_entity
  end

  test "GET confirm with valid token confirms user and logs in" do
    token = users(:unconfirmed).confirmation_token
    get confirm_registration_path(token: token)
    assert_redirected_to dashboard_path
    assert_includes flash[:notice], "confirmed"
    assert users(:unconfirmed).reload.confirmed?
  end

  test "GET confirm clears confirmation token after confirming" do
    token = users(:unconfirmed).confirmation_token
    get confirm_registration_path(token: token)
    assert_nil users(:unconfirmed).reload.confirmation_token
  end

  test "GET confirm with invalid token redirects with alert" do
    get confirm_registration_path(token: "badtoken")
    assert_redirected_to root_path
    assert_includes flash[:alert], "Invalid"
  end

  test "GET confirm for already confirmed user redirects with alert" do
    user = User.create!(
      email_address: "already@example.com",
      password: "supersecret",
      confirmed: true,
      confirmation_token: "alreadyconfirmedtoken1234567890123"
    )
    get confirm_registration_path(token: user.confirmation_token)
    assert_redirected_to root_path
    assert_includes flash[:alert], "Invalid"
  end
end
