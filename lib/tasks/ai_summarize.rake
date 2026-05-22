namespace :articles do
  desc "Summarize unprocessed articles with Claude AI"
  task ai_summarize: :environment do
    require "net/http"
    require "json"
    api_key = Rails.application.credentials.anthropic_api_key || ENV["ANTHROPIC_API_KEY"]
    unless api_key
      puts "ANTHROPIC_API_KEY not set, skipping"
      next
    end

    articles = Article.unprocessed.where(relevant: true).order(published_at: :desc)
    puts "Processing #{articles.count} articles..."

    articles.each do |article|
      puts "  Summarizing: #{article.title[0..60]}..."

      result = call_claude(article, api_key)

      if result
        article.update!(
          relevant: result[:relevant],
          summary_tr: result[:summary_tr],
          summary_en: result[:summary_en],
          score: result[:score],
          ai_filtered: true
        )
        puts "    Score: #{result[:score]}, Relevant: #{result[:relevant]}"
      else
        article.update!(ai_filtered: true)
        puts "    Failed to process, marked as filtered"
      end
    rescue => e
      puts "  Error processing article #{article.id}: #{e.message}"
    end

    puts "Done."
  end
end

task ai_summarize: "articles:ai_summarize"

def call_claude(article, api_key)
  prompt = <<~PROMPT
    You are a Ruby/Rails community curator. Evaluate this article and respond with valid JSON only.

    Title: #{article.title}
    Source: #{article.source}
    URL: #{article.url}

    Respond with this exact JSON structure:
    {
      "relevant": true/false,
      "score": 1-10,
      "summary_en": "2-3 sentence English summary, null if not relevant",
      "summary_tr": "2-3 sentence Turkish summary, null if not relevant"
    }

    Rules:
    - relevant: true only if about Ruby, Rails, gems, Ruby community, or closely related tech
    - score: 1-10 based on importance/interest to Ruby developers
    - summaries: concise, informative, highlight key points
    - If not relevant, set relevant to false and summaries to null
  PROMPT

  uri = URI("https://api.anthropic.com/v1/messages")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 30

  request = Net::HTTP::Post.new(uri)
  request["x-api-key"] = api_key
  request["anthropic-version"] = "2023-06-01"
  request["content-type"] = "application/json"
  request.body = JSON.generate({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 512,
    messages: [ { role: "user", content: prompt } ]
  })

  response = http.request(request)

  unless response.code == "200"
    puts "    API error: #{response.code}"
    return nil
  end

  body = JSON.parse(response.body)
  text = body.dig("content", 0, "text").to_s.strip

  text = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip

  parsed = JSON.parse(text)
  {
    relevant: parsed["relevant"] == true,
    score: parsed["score"].to_i.clamp(1, 10),
    summary_en: parsed["summary_en"],
    summary_tr: parsed["summary_tr"]
  }
rescue JSON::ParserError => e
  puts "    JSON parse error: #{e.message}"
  nil
rescue => e
  puts "    Error: #{e.message}"
  nil
end
