require "test_helper"

class Shared::LobbyControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shared_lobby_index_url
    assert_response :success
  end
end
