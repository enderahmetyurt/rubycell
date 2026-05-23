# RubyCell

An open source Ruby news digest platform. Aggregates RSS feeds from Ruby blogs and community sites, summarizes articles with AI, and delivers curated digests to subscribers.

## Features

- Aggregates RSS/Atom feeds from an OPML file
- AI-powered relevance filtering and summarization (English + Turkish) via Claude
- Email digests (daily or weekly) via Resend
- Free tier (titles + links) and paid tier ($1/year, includes AI summaries)
- Self-hostable: bring your own `ANTHROPIC_API_KEY` to enable AI summaries for free

## Tech Stack

- Ruby on Rails (main branch)
- SQLite
- Tailwind CSS
- Solid Queue
- Resend (email delivery)
- Lemon Squeezy (payments)

## Quick Start

```bash
git clone https://github.com/yourusername/rubycell
cd rubycell
bundle install
rails db:migrate
bin/dev
```

## Rake Tasks

```bash
rake fetch          # Fetch articles from feeds.opml
rake ai_summarize   # Summarize with Claude AI (requires ANTHROPIC_API_KEY)
rake send_digest    # Send email digest (requires RESEND_API_KEY)
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes (for AI) | Claude API key for summarization |
| `RESEND_API_KEY` | Yes (for email) | Resend API key for email delivery |
| `LEMONSQUEEZY_API_KEY` | Yes (for payments) | Lemon Squeezy API key |
| `LEMONSQUEEZY_VARIANT_ID` | Yes (for payments) | Lemon Squeezy product variant ID |
| `LEMONSQUEEZY_WEBHOOK_SECRET` | Recommended | HMAC secret to verify webhook payloads |
| `MAIL_FROM` | No | Sender email address (default: noreply@rubycell.com) |
| `APP_HOST` | No | App hostname for email links (default: rubycell.com) |
| `SECRET_KEY_BASE` | Yes (production) | Rails secret key base |

## Credits

Feed fetching logic inspired by and adapted from **Planet Ruby** by Peter Cooper.  
[https://github.com/peterc/planetruby](https://github.com/peterc/planetruby) — MIT License

## Self-Hosting

See [HOSTING.md](HOSTING.md) for detailed setup instructions.

## License

MIT License — see [LICENSE](LICENSE).
