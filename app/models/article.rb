class Article < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  validates :title, presence: true

  scope :relevant, -> { where(relevant: true) }
  scope :unprocessed, -> { where(ai_filtered: false) }
  scope :recent, -> { where(published_at: 24.hours.ago..) }
  scope :last_week, -> { where(published_at: 7.days.ago..) }

  def self.for_digest(frequency)
    case frequency.to_s
    when "daily" then relevant.recent.order(score: :desc, published_at: :desc)
    when "weekly" then relevant.last_week.order(score: :desc, published_at: :desc)
    else all.none
    end
  end
end
