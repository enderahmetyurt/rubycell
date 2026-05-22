require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders login form" do
    get new_session_path
    assert_response :success
  end

  test "POST create with valid credentials starts session and redirects" do
    post session_path, params: { email_address: "alice@example.com", password: "password" }
    assert_redirected_to root_url
  end

  test "POST create with invalid password redirects with alert" do
    post session_path, params: { email_address: "alice@example.com", password: "wrong" }
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "POST create with unknown email redirects with alert" do
    post session_path, params: { email_address: "nobody@example.com", password: "password" }
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "DELETE destroy terminates session and redirects" do
    sign_in users(:alice)
    delete session_path
    assert_redirected_to new_session_path
  end
end
