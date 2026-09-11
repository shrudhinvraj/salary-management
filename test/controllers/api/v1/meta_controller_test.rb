require "test_helper"

class Api::V1::MetaControllerTest < ActionDispatch::IntegrationTest
  test "index returns lookup data for forms" do
    create_country
    create_department

    get "/api/v1/meta"
    body = JSON.parse(response.body)

    assert_response :success
    assert_equal 1, body.dig("data", "countries").length
    assert_equal 1, body.dig("data", "departments").length
    assert_includes body.dig("data", "statuses"), "active"
    assert_includes body.dig("data", "genders"), "female"
  end
end