require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  def valid_article(attrs = {})
    Article.new({
      title: "Ruby 3.4 Released",
      url: "https://www.ruby-lang.org/en/news/2024/12/25/ruby-3-4-0-released/",
      source: "Ruby Blog",
      published_at: 1.hour.ago
    }.merge(attrs))
  end

  test "saves with valid attributes" do
    article = valid_article
    assert article.save
  end

  test "requires title" do
    article = valid_article(title: "")
    assert_not article.valid?
  end

  test "requires url" do
    article = valid_article(url: "")
    assert_not article.valid?
  end

  test "url must be unique" do
    valid_article.save!
    dup = valid_article
    assert_not dup.valid?
  end

  test "defaults ai_filtered to false" do
    article = valid_article
    article.save!
    assert_equal false, article.ai_filtered
  end

  test "defaults relevant to true" do
    article = valid_article
    article.save!
    assert_equal true, article.relevant
  end

  test "relevant scope returns only relevant articles" do
    valid_article(url: "https://example.com/1").save!
    valid_article(url: "https://example.com/2", relevant: false).save!
    assert_equal 1, Article.relevant.count
  end

  test "unprocessed scope returns only unfiltered articles" do
    valid_article(url: "https://example.com/1").save!
    valid_article(url: "https://example.com/2", ai_filtered: true).save!
    assert_equal 1, Article.unprocessed.count
  end

  test "recent scope returns articles from last 24h" do
    valid_article(url: "https://example.com/1", published_at: 1.hour.ago).save!
    valid_article(url: "https://example.com/2", published_at: 2.days.ago).save!
    assert_equal 1, Article.recent.count
  end

  test "last_week scope returns articles from last 7 days" do
    valid_article(url: "https://example.com/1", published_at: 3.days.ago).save!
    valid_article(url: "https://example.com/2", published_at: 8.days.ago).save!
    assert_equal 1, Article.last_week.count
  end

  test "for_digest with daily returns recent relevant articles" do
    valid_article(url: "https://example.com/1", published_at: 1.hour.ago).save!
    valid_article(url: "https://example.com/2", published_at: 2.days.ago).save!
    assert_equal 1, Article.for_digest("daily").count
  end

  test "for_digest with weekly returns last 7 days relevant articles" do
    valid_article(url: "https://example.com/1", published_at: 3.days.ago).save!
    valid_article(url: "https://example.com/2", published_at: 8.days.ago).save!
    assert_equal 1, Article.for_digest("weekly").count
  end

  test "for_digest with unsubscribed returns nothing" do
    valid_article.save!
    assert_equal 0, Article.for_digest("unsubscribed").count
  end

  test "for_digest excludes irrelevant articles" do
    valid_article(url: "https://example.com/1", published_at: 1.hour.ago, relevant: false).save!
    assert_equal 0, Article.for_digest("daily").count
  end
end
