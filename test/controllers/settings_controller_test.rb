require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "GET show requires authentication" do
    get settings_path
    assert_redirected_to new_session_path
  end

  test "GET show renders settings for authenticated user" do
    sign_in users(:alice)
    get settings_path
    assert_response :success
  end

  test "PATCH update requires authentication" do
    patch settings_path, params: { user: { language: "lang_tr" } }
    assert_redirected_to new_session_path
  end

  test "PATCH update with valid params updates user and redirects" do
    sign_in users(:alice)
    patch settings_path, params: { user: { language: "lang_tr", frequency: "weekly" } }
    assert_redirected_to settings_path
    assert_includes flash[:notice], "Settings updated"
    assert users(:alice).reload.lang_tr?
    assert users(:alice).reload.weekly?
  end

  test "PATCH update language to lang_en" do
    sign_in users(:alice)
    patch settings_path, params: { user: { language: "lang_en", frequency: "daily" } }
    assert_redirected_to settings_path
    assert users(:alice).reload.lang_en?
    assert users(:alice).reload.daily?
  end
end
