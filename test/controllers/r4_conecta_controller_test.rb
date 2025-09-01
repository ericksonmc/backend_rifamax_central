require "test_helper"

class R4ConectaControllerTest < ActionDispatch::IntegrationTest
  test "should get R4consulta" do
    get r4_conecta_R4consulta_url
    assert_response :success
  end

  test "should get R4notifica" do
    get r4_conecta_R4notifica_url
    assert_response :success
  end
end
