require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "belongs to user" do
    session = sessions(:alice_session)
    assert_equal users(:alice), session.user
  end

  test "invalid without user" do
    session = Session.new(ip_address: "127.0.0.1")
    assert_not session.valid?
  end

  test "valid with user" do
    session = Session.new(user: users(:alice), ip_address: "127.0.0.1")
    assert session.valid?
  end

  test "destroyed when user is destroyed" do
    alice = users(:alice)
    session_id = sessions(:alice_session).id
    alice.destroy
    assert_nil Session.find_by(id: session_id)
  end
end
