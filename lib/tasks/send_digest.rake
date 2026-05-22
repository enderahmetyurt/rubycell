namespace :articles do
  desc "Send digest emails to subscribers"
  task send_digest: :environment do
    require "net/http"
    require "json"
    api_key = ENV["RESEND_API_KEY"]
    unless api_key
      puts "RESEND_API_KEY not set, skipping"
      next
    end

    today_monday = Date.today.monday?

    recipients = User.where(frequency: [:daily, :weekly]).where(confirmed: true)
    puts "Found #{recipients.count} confirmed subscribers"

    recipients.each do |user|
      next if user.frequency == "weekly" && !today_monday

      frequency = user.frequency
      articles = Article.for_digest(frequency)

      if articles.empty?
        puts "  No articles for #{user.email_address}, skipping"
        next
      end

      subject, body = build_email(user, articles, frequency)
      send_via_resend(user.email_address, subject, body, api_key)
      puts "  Sent #{frequency} digest to #{user.email_address} (#{articles.count} articles)"
    rescue => e
      puts "  Error for #{user.email_address}: #{e.message}"
    end

    puts "Done."
  end
end

task send_digest: "articles:send_digest"

def build_email(user, articles, frequency)
  period = frequency == "daily" ? "Daily" : "Weekly"
  date_str = Date.today.strftime("%B %d, %Y")
  subject = "RubyCell #{period} Digest — #{date_str}"

  lines = ["<h2>RubyCell #{period} Digest &mdash; #{date_str}</h2>", "<ul style='padding:0;list-style:none'>"]

  articles.each do |article|
    lines << "<li style='margin-bottom:16px;padding-bottom:16px;border-bottom:1px solid #eee'>"
    lines << "<strong><a href='#{article.url}' style='color:#b91c1c;text-decoration:none'>#{article.title}</a></strong>"
    lines << "<br><small style='color:#666'>#{article.source} &middot; #{article.published_at&.strftime('%b %d')}</small>"

    if user.paid_active?
      summary = user.lang_tr? ? article.summary_tr : article.summary_en
      summary ||= article.summary_en || article.summary_tr
      lines << "<p style='margin:4px 0 0;color:#444;font-size:14px'>#{summary}</p>" if summary.present?
    end

    lines << "</li>"
  end

  lines << "</ul>"
  lines << "<p style='color:#999;font-size:12px;margin-top:24px'>You're receiving this because you subscribed to RubyCell. <a href=''>Manage preferences</a>.</p>"

  [subject, lines.join("\n")]
end

def send_via_resend(to, subject, html_body, api_key)
  uri = URI("https://api.resend.com/emails")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 15

  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{api_key}"
  request["Content-Type"] = "application/json"
  request.body = JSON.generate({
    from: ENV.fetch("MAIL_FROM", "RubyCell <noreply@rubycell.com>"),
    to: [to],
    subject: subject,
    html: html_body
  })

  response = http.request(request)
  unless response.code.start_with?("2")
    raise "Resend API error #{response.code}: #{response.body}"
  end
end
