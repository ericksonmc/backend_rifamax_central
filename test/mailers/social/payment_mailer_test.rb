require "test_helper"

class Social::PaymentMailerTest < ActionMailer::TestCase
  test "pre_order_email" do
    mail = Social::PaymentMailer.pre_order_email
    assert_equal "Pre order email", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "order_email" do
    mail = Social::PaymentMailer.order_email
    assert_equal "Order email", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
