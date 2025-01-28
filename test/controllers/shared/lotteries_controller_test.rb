require "test_helper"

class Shared::LotteriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shared_lotteries_index_url
    assert_response :success
  end
end
