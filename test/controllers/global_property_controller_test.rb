require 'test_helper'

class GlobalPropertyControllerTest < ActionController::TestCase
  test "should get paper" do
    get :paper
    assert_response :success
  end

  test "should get signature" do
    get :signature
    assert_response :success
  end

  test "should get set_paper" do
    get :set_paper
    assert_response :success
  end

  test "should get set_signature" do
    get :set_signature
    assert_response :success
  end

  test "should get update_paper" do
    get :update_paper
    assert_response :success
  end

  test "should get update_signature" do
    get :update_signature
    assert_response :success
  end

end
