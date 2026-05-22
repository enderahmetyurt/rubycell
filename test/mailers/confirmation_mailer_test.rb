require "test_helper"

class ConfirmationMailerTest < ActionMailer::TestCase
  test "confirmation mail sent to user email" do
    user = users(:unconfirmed)
    mail = ConfirmationMailer.confirmation(user)
    assert_equal [ user.email_address ], mail.to
  end

  test "confirmation mail has correct subject" do
    user = users(:unconfirmed)
    mail = ConfirmationMailer.confirmation(user)
    assert_equal "Confirm your RubyCell account", mail.subject
  end

  test "confirmation mail body contains confirmation URL" do
    user = users(:unconfirmed)
    mail = ConfirmationMailer.confirmation(user)
    assert_match user.confirmation_token, mail.body.encoded
  end
end
