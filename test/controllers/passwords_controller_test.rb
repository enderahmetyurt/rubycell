require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders password reset form" do
    get new_password_path
    assert_response :success
  end

  test "POST create with existing email redirects with notice" do
    post passwords_path, params: { email_address: "alice@example.com" }
    assert_redirected_to new_session_path
    assert_includes flash[:notice], "reset instructions"
  end

  test "POST create with unknown email redirects with same notice" do
    post passwords_path, params: { email_address: "nobody@example.com" }
    assert_redirected_to new_session_path
    assert_includes flash[:notice], "reset instructions"
  end

  test "POST create with existing email enqueues reset email" do
    assert_emails 1 do
      post passwords_path, params: { email_address: "alice@example.com" }
    end
  end

  test "GET edit with valid token renders form" do
    token = users(:alice).password_reset_token
    get edit_password_path(token)
    assert_response :success
  end

  test "GET edit with invalid token redirects with alert" do
    get edit_password_path("invalidtoken")
    assert_redirected_to new_password_path
    assert_includes flash[:alert], "invalid or has expired"
  end

  test "PATCH update with valid token and matching passwords resets password" do
    token = users(:alice).password_reset_token
    patch password_path(token), params: { password: "newpassword", password_confirmation: "newpassword" }
    assert_redirected_to new_session_path
    assert_includes flash[:notice], "Password has been reset"
  end

  test "PATCH update destroys all user sessions on password reset" do
    alice = users(:alice)
    token = alice.password_reset_token
    patch password_path(token), params: { password: "newpassword", password_confirmation: "newpassword" }
    assert_equal 0, alice.reload.sessions.count
  end

  test "PATCH update with mismatched passwords redirects with alert" do
    token = users(:alice).password_reset_token
    patch password_path(token), params: { password: "newpassword", password_confirmation: "different" }
    assert_redirected_to edit_password_path(token)
    assert_includes flash[:alert], "did not match"
  end
end
