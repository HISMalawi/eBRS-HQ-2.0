require 'test_helper'

class LocationControllerTest < ActionController::TestCase
  test "should get sites" do
    get :sites
    assert_response :success
  end

end
