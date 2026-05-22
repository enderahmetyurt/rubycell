class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :language, { lang_tr: 0, lang_en: 1, lang_both: 2 }, default: :lang_both
  enum :frequency, { daily: 0, weekly: 1, unsubscribed: 2 }, default: :unsubscribed
  enum :plan, { free: 0, paid: 1 }, default: :free

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_create :generate_confirmation_token

  def paid_active?
    paid? && plan_expires_at&.future?
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
  end
end
