# Based on Planet Ruby's fetch.rb (MIT License)
# https://github.com/peterc/planetruby

namespace :articles do
  desc "Fetch articles from OPML feeds, save new ones, drop articles older than 7 days"
  task fetch: :environment do
    require "rss"
    require "open-uri"
    require "rexml/document"
    require "net/http"

    opml_path = Rails.root.join("feeds.opml")

    unless File.exist?(opml_path)
      puts "feeds.opml not found at #{opml_path}"
      next
    end

    feed_urls = parse_opml(opml_path)
    puts "Found #{feed_urls.size} feeds"

    Article.where("published_at < ?", 7.days.ago).delete_all

    results = fetch_feeds_concurrently(feed_urls)

    saved = 0
    results.each do |items|
      next unless items

      items.each do |item|
        next unless item[:url].present? && item[:title].present?

        article = Article.find_or_initialize_by(url: item[:url])
        next unless article.new_record?

        article.assign_attributes(
          title: item[:title].to_s.strip,
          source: item[:source].to_s.strip,
          source_url: item[:source_url].to_s.strip,
          published_at: item[:published_at] || Time.current
        )

        if article.save
          saved += 1
        end
      rescue => e
        puts "  Error saving article: #{e.message}"
      end
    end

    puts "Saved #{saved} new articles"
  end
end

task fetch: "articles:fetch"

def parse_opml(path)
  require "rexml/document"
  doc = REXML::Document.new(File.read(path))
  urls = []
  doc.elements.each("//outline[@type='rss']") do |el|
    url = el.attributes["xmlUrl"] || el.attributes["xmlurl"]
    urls << url if url
  end
  doc.elements.each("//outline[@xmlUrl]") do |el|
    url = el.attributes["xmlUrl"]
    urls << url if url && !urls.include?(url)
  end
  urls.uniq
end

def fetch_feeds_concurrently(urls)
  threads = urls.map do |url|
    Thread.new { fetch_feed(url) }
  end
  threads.map { |t| t.join; t.value }
end

def fetch_feed(url)
  require "rss"
  require "open-uri"
  feed = RSS::Parser.parse(
    URI.open(url, "User-Agent" => "RubyCell/1.0", read_timeout: 10, open_timeout: 10),
    false
  )
  return [] unless feed

  source_title = feed.channel&.title.to_s.strip
  source_url   = feed.channel&.link.to_s.strip

  items = feed.items.map do |item|
    published = nil
    published ||= item.pubDate if item.respond_to?(:pubDate)
    published ||= item.dc_date if item.respond_to?(:dc_date)
    published ||= item.date if item.respond_to?(:date)
    published ||= Time.current

    link = ""
    link = item.link.to_s.strip if item.respond_to?(:link)
    link = item.links&.first&.href.to_s.strip if link.blank? && item.respond_to?(:links)

    {
      title: item.title.to_s.strip,
      url: link,
      source: source_title,
      source_url: source_url,
      published_at: published
    }
  end

  items.select { |i| i[:url].present? && i[:published_at] > 7.days.ago }
rescue => e
  puts "  Error fetching #{url}: #{e.message}"
  []
end
