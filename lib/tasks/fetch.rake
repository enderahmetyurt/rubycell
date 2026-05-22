# Based on Planet Ruby's fetch.rb (MIT License)
# https://github.com/peterc/planetruby

require "net/http"
require "uri"
require "rss"
require "rexml/document"
require "json"

FETCH_TIMEOUT = 15
MAX_REDIRECTS = 5
THREAD_COUNT  = 4
USER_AGENT    = "RubyCell/1.0"
MAX_AGE_DAYS  = 30

namespace :articles do
  desc "Fetch articles from OPML feeds, save new ones, drop articles older than #{MAX_AGE_DAYS} days"
  task fetch: :environment do
    opml_path = Rails.root.join("feeds.opml")

    unless File.exist?(opml_path)
      puts "feeds.opml not found at #{opml_path}"
      next
    end

    feeds = rc_parse_opml(opml_path)
    puts "Found #{feeds.size} feeds"

    Article.where("published_at < ?", MAX_AGE_DAYS.days.ago).delete_all

    cutoff = MAX_AGE_DAYS.days.ago
    etag_path = Rails.root.join("tmp/feed_etags.json")
    etag_cache = File.exist?(etag_path) ? JSON.parse(File.read(etag_path)) : {}

    fresh_items = []
    success_count = 0
    not_modified_count = 0
    error_count = 0
    mutex = Mutex.new

    queue = Queue.new
    feeds.each { |feed| queue << feed }
    THREAD_COUNT.times { queue << nil }

    threads = THREAD_COUNT.times.map do
      Thread.new do
        thread_items = []

        while (feed = queue.pop)
          name = feed[:name]
          url  = feed[:url]

          begin
            conditional = {}
            if (cached = etag_cache[url])
              conditional["If-None-Match"]     = cached["etag"]          if cached["etag"]
              conditional["If-Modified-Since"] = cached["last_modified"] if cached["last_modified"]
            end

            response = rc_fetch_url(url, headers: conditional)

            if response.nil?
              mutex.synchronize { not_modified_count += 1 }
              next
            end

            mutex.synchronize do
              etag_cache[url] = {
                "etag"          => response["etag"],
                "last_modified" => response["last-modified"]
              }.compact
            end

            items = rc_parse_feed(response.body, name, url, cutoff: cutoff)
            thread_items.concat(items)
            mutex.synchronize do
              success_count += 1
              puts "  #{name}: #{items.size} items"
            end
          rescue => e
            mutex.synchronize do
              error_count += 1
              puts "  #{name}: ERROR: #{e.message}"
            end
          end
        end

        thread_items
      end
    end

    threads.each { |t| fresh_items.concat(t.value) }

    File.write(etag_path, JSON.pretty_generate(etag_cache))

    saved = 0
    fresh_items.each do |item|
      next if item[:url].blank? || item[:title].blank?

      article = Article.find_or_initialize_by(url: item[:url])
      next unless article.new_record?

      article.assign_attributes(
        title:        item[:title],
        source:       item[:source],
        source_url:   item[:source_url],
        published_at: item[:published_at]
      )

      saved += 1 if article.save
    rescue => e
      puts "  Error saving article: #{e.message}"
    end

    puts "\nDone. +#{saved} new articles from #{success_count} feeds (#{not_modified_count} unchanged, #{error_count} errors)."
  end
end

task fetch: "articles:fetch"

def rc_fetch_url(url, headers: {}, redirect_limit: MAX_REDIRECTS)
  raise "Too many redirects" if redirect_limit == 0

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl      = uri.scheme == "https"
  http.open_timeout = FETCH_TIMEOUT
  http.read_timeout = FETCH_TIMEOUT

  request = Net::HTTP::Get.new(uri.request_uri)
  request["User-Agent"] = USER_AGENT
  headers.each { |k, v| request[k] = v }

  response = http.request(request)

  case response
  when Net::HTTPNotModified then nil
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection
    location = response["location"]
    location = URI.join(url, location).to_s unless location.start_with?("http")
    rc_fetch_url(location, headers: headers, redirect_limit: redirect_limit - 1)
  else
    raise "HTTP #{response.code}: #{response.message}"
  end
end

def rc_feed_site_url(feed)
  candidates = []

  if feed.respond_to?(:links) && feed.links&.any?
    alt = feed.links.find { |l| l.rel == "alternate" }
    candidates << alt.href.to_s.strip if alt&.respond_to?(:href)
    feed.links.each { |l| candidates << l.href.to_s.strip if l.respond_to?(:href) }
  end

  if feed.respond_to?(:channel) && feed.channel&.respond_to?(:link)
    candidates << feed.channel.link.to_s.strip
  end

  if feed.respond_to?(:link) && feed.link
    l = feed.link
    candidates << (l.respond_to?(:href) ? l.href : l).to_s.strip
  end

  candidates
    .reject(&:empty?)
    .reject { |u| u.match?(/\.(xml|rss|atom|json|rdf)(\?|$)/i) }
    .reject { |u| u.match?(%r{/(feed|atom|rss)(/|$)}i) }
    .reject { |u| u == "/" }
    .first || ""
end

def rc_parse_feed(xml, source_name, feed_url, cutoff:)
  feed = RSS::Parser.parse(xml, false)
  return [] unless feed

  source_url = rc_feed_site_url(feed)
  items = []

  feed.items.each do |item|
    title = item.title
    title = title.respond_to?(:content) ? title.content.to_s : title.to_s
    title = title.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
    next if title.empty?

    link = if item.respond_to?(:link) && item.link
      l = item.link
      l.respond_to?(:href) ? l.href.to_s : l.to_s
    elsif item.respond_to?(:links) && item.links&.any?
      item.links.first.href.to_s
    else
      ""
    end
    link = link.strip
    next if link.empty?
    link = URI.join(feed_url, link).to_s unless link.start_with?("http")

    pub_date = if item.respond_to?(:pubDate) && item.pubDate
      item.pubDate
    elsif item.respond_to?(:published) && item.published
      d = item.published
      d.respond_to?(:content) ? d.content : d
    elsif item.respond_to?(:date) && item.date
      item.date
    elsif item.respond_to?(:updated) && item.updated
      d = item.updated
      d.respond_to?(:content) ? d.content : d
    end

    next unless pub_date
    pub_date = pub_date.is_a?(Time) ? pub_date : Time.parse(pub_date.to_s) rescue next
    next if pub_date < cutoff

    items << {
      title:        title,
      url:          link,
      published_at: pub_date,
      source:       source_name,
      source_url:   source_url
    }
  end

  items
end

def rc_parse_opml(path)
  doc = REXML::Document.new(File.read(path))
  feeds = []

  doc.elements.each("//outline") do |outline|
    xml_url = outline.attributes["xmlUrl"]
    next if xml_url.nil? || xml_url.strip.empty?

    feeds << {
      name: (outline.attributes["title"] || outline.attributes["text"] || xml_url).strip,
      url:  xml_url.strip
    }
  end

  feeds.uniq { |f| f[:url] }
end
