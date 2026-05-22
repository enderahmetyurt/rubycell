require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_user(attrs = {})
    User.new({
      email_address: "test@example.com",
      password: "supersecretpassword",
      password_confirmation: "supersecretpassword"
    }.merge(attrs))
  end

  test "saves with valid attributes" do
    user = valid_user
    assert user.save
  end

  test "requires email" do
    user = valid_user(email_address: "")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email must be unique" do
    valid_user.save!
    dup = valid_user(email_address: "TEST@EXAMPLE.COM")
    assert_not dup.valid?
  end

  test "normalizes email to lowercase" do
    user = valid_user(email_address: "RUBY@EXAMPLE.COM")
    user.save!
    assert_equal "ruby@example.com", user.email_address
  end

  test "defaults to lang_both language" do
    user = valid_user
    user.save!
    assert user.lang_both?
  end

  test "defaults to unsubscribed frequency" do
    user = valid_user
    user.save!
    assert user.unsubscribed?
  end

  test "defaults to free plan" do
    user = valid_user
    user.save!
    assert user.free?
  end

  test "defaults confirmed to false" do
    user = valid_user
    user.save!
    assert_equal false, user.confirmed
  end

  test "generates confirmation token before create" do
    user = valid_user
    user.save!
    assert_not_nil user.confirmation_token
    assert user.confirmation_token.length >= 20
  end

  test "paid_active? returns false for free user" do
    user = valid_user
    user.save!
    assert_not user.paid_active?
  end

  test "paid_active? returns false for paid user with expired plan" do
    user = valid_user
    user.save!
    user.update!(plan: :paid, plan_expires_at: 1.day.ago)
    assert_not user.paid_active?
  end

  test "paid_active? returns true for paid user with future expiry" do
    user = valid_user
    user.save!
    user.update!(plan: :paid, plan_expires_at: 1.year.from_now)
    assert user.paid_active?
  end

  test "language enum values" do
    user = valid_user
    user.save!
    user.update!(language: :lang_tr)
    assert user.lang_tr?
    user.update!(language: :lang_en)
    assert user.lang_en?
    user.update!(language: :lang_both)
    assert user.lang_both?
  end

  test "frequency enum values" do
    user = valid_user
    user.save!
    user.update!(frequency: :daily)
    assert user.daily?
    user.update!(frequency: :weekly)
    assert user.weekly?
    user.update!(frequency: :unsubscribed)
    assert user.unsubscribed?
  end
end
