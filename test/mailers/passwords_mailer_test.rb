require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset mail sent to user email" do
    user = users(:alice)
    mail = PasswordsMailer.reset(user)
    assert_equal [ user.email_address ], mail.to
  end

  test "reset mail has correct subject" do
    user = users(:alice)
    mail = PasswordsMailer.reset(user)
    assert_equal "Reset your password", mail.subject
  end
end
