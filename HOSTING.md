# Self-Hosting RubyCell

## Prerequisites

- Ruby 3.4+
- Bundler
- SQLite3
- An Anthropic API key (for AI summaries)
- A Resend account (for email delivery)
- A Lemon Squeezy account (for payments, optional)

## Setup

### 1. Clone and install

```bash
git clone https://github.com/yourusername/rubycell
cd rubycell
bundle install
```

### 2. Set environment variables

Copy `.env.example` to `.env` (or set in your deployment environment):

```bash
ANTHROPIC_API_KEY=sk-ant-...
RESEND_API_KEY=re_...
LEMONSQUEEZY_API_KEY=...
LEMONSQUEEZY_VARIANT_ID=...
LEMONSQUEEZY_WEBHOOK_SECRET=...
MAIL_FROM=RubyCell <noreply@yourdomain.com>
APP_HOST=yourdomain.com
SECRET_KEY_BASE=$(bundle exec rails secret)
RAILS_MASTER_KEY=...
```

### 3. Database setup

```bash
RAILS_ENV=production bundle exec rails db:migrate
```

### 4. Precompile assets

```bash
RAILS_ENV=production bundle exec rails assets:precompile
```

### 5. Start the server

```bash
bundle exec puma -C config/puma.rb
```

Or with `bin/dev` for development.

## Configure feeds

Edit `feeds.opml` in the Rails root to add your RSS/Atom feed sources. The file uses standard OPML format:

```xml
<outline type="rss" text="My Blog" xmlUrl="https://myblog.com/feed.xml" htmlUrl="https://myblog.com"/>
```

## Running the digest pipeline

The digest pipeline is three rake tasks:

```bash
# Fetch new articles from feeds
bundle exec rake fetch

# Summarize with AI (requires ANTHROPIC_API_KEY)
bundle exec rake ai_summarize

# Send email digests (requires RESEND_API_KEY)
bundle exec rake send_digest
```

Run these on a schedule (e.g., daily at 8am):

```bash
0 5 * * * cd /path/to/rubycell && bundle exec rake fetch ai_summarize send_digest
```

Or use the included GitHub Actions workflow (`.github/workflows/digest.yml`) — set `DATABASE_URL` to your production database URL in secrets.

## GitHub Actions setup

Add these secrets to your GitHub repository:

- `DATABASE_URL` — production database URL
- `ANTHROPIC_API_KEY`
- `RESEND_API_KEY`
- `SECRET_KEY_BASE`
- `RAILS_MASTER_KEY`

The workflow runs daily at 05:00 UTC (08:00 Turkey time).

## AI summaries without paying

If you self-host and set your own `ANTHROPIC_API_KEY`, all users on your instance get AI summaries regardless of plan. You can disable payments entirely by not configuring Lemon Squeezy.

## Payments (Lemon Squeezy)

1. Create a product in Lemon Squeezy for $1/year
2. Note your **Variant ID**
3. Set `LEMONSQUEEZY_VARIANT_ID` env var
4. Configure a webhook pointing to `https://yourdomain.com/webhooks/lemonsqueezy`
5. Set `LEMONSQUEEZY_WEBHOOK_SECRET` to verify webhook signatures

## Email (Resend)

1. Create an account at [resend.com](https://resend.com)
2. Verify your sending domain
3. Create an API key
4. Set `RESEND_API_KEY` and `MAIL_FROM`
