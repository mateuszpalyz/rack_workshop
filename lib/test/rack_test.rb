require 'minitest/autorun'
require 'rack/test'
require '../hello_rack'

class RackTest < Minitest::Test
  include Rack::Test::Methods

  def app
    HelloRack.new
  end

  def setup
    get "/"
  end

  def test_response_status
    assert last_response.ok?
  end

  def test_response_body
    assert_equal "Hello Rack", last_response.body
  end
end
