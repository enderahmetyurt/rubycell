require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    Article.delete_all
    @recent_article = Article.create!(
      title: "Recent Ruby News",
      url: "https://example.com/recent",
      source: "Ruby Blog",
      published_at: 2.hours.ago,
      relevant: true,
      ai_filtered: true,
      score: 90,
      summary_en: "Great new Ruby release.",
      summary_tr: "Harika Ruby sürümü."
    )
    @irrelevant_article = Article.create!(
      title: "Irrelevant Article",
      url: "https://example.com/irrelevant",
      source: "Random Blog",
      published_at: 1.hour.ago,
      relevant: false,
      ai_filtered: true
    )
    @no_summary_article = Article.create!(
      title: "No Summary Article",
      url: "https://example.com/nosummary",
      source: "Some Blog",
      published_at: 1.hour.ago,
      relevant: true,
      ai_filtered: true
    )
  end

  def after_teardown
    Article.delete_all
    super
  end

  test "GET index requires authentication" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "GET index renders for authenticated user" do
    sign_in users(:alice)
    get dashboard_path
    assert_response :success
  end

  test "GET index does not show irrelevant articles" do
    sign_in users(:alice)
    get dashboard_path
    assert_not_includes response.body, @irrelevant_article.title
  end

  test "GET index shows relevant articles for lang_both user" do
    users(:alice).update!(language: :lang_both)
    sign_in users(:alice)
    get dashboard_path
    assert_includes response.body, @recent_article.title
  end

  test "GET index filters articles without turkish summary for lang_tr user" do
    users(:alice).update!(language: :lang_tr)
    sign_in users(:alice)
    get dashboard_path
    assert_includes response.body, @recent_article.title
    assert_not_includes response.body, @no_summary_article.title
  end

  test "GET index filters articles without english summary for lang_en user" do
    users(:alice).update!(language: :lang_en)
    sign_in users(:alice)
    get dashboard_path
    assert_includes response.body, @recent_article.title
    assert_not_includes response.body, @no_summary_article.title
  end
end
