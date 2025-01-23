require "test_helper"

class Shared::CurrenciesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shared_currencies_index_url
    assert_response :success
  end
end
