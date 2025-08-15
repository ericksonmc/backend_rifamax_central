require "test_helper"

class Social::ContextsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @social_context = social_contexts(:one)
  end

  test "should get index" do
    get social_contexts_url, as: :json
    assert_response :success
  end

  test "should create social_context" do
    assert_difference("Social::Context.count") do
      post social_contexts_url, params: { social_context: { context: @social_context.context, key: @social_context.key } }, as: :json
    end

    assert_response :created
  end

  test "should show social_context" do
    get social_context_url(@social_context), as: :json
    assert_response :success
  end

  test "should update social_context" do
    patch social_context_url(@social_context), params: { social_context: { context: @social_context.context, key: @social_context.key } }, as: :json
    assert_response :success
  end

  test "should destroy social_context" do
    assert_difference("Social::Context.count", -1) do
      delete social_context_url(@social_context), as: :json
    end

    assert_response :no_content
  end
end
