require "test_helper"

class Social::LotteriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @social_lottery = social_lotteries(:one)
  end

  test "should get index" do
    get social_lotteries_url, as: :json
    assert_response :success
  end

  test "should create social_lottery" do
    assert_difference("Social::Lottery.count") do
      post social_lotteries_url, params: { social_lottery: {  } }, as: :json
    end

    assert_response :created
  end

  test "should show social_lottery" do
    get social_lottery_url(@social_lottery), as: :json
    assert_response :success
  end

  test "should update social_lottery" do
    patch social_lottery_url(@social_lottery), params: { social_lottery: {  } }, as: :json
    assert_response :success
  end

  test "should destroy social_lottery" do
    assert_difference("Social::Lottery.count", -1) do
      delete social_lottery_url(@social_lottery), as: :json
    end

    assert_response :no_content
  end
end
