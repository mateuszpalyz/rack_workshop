require 'minitest/autorun'
require 'rack/test'
require '../hello_rack'
require '../middleware'

class RackTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    @app = HelloRack.new
    @middleware = Middleware.new(@app, { limit: 100 })
  end

  def test_response
    assert_equal [200, {"Content-Type"=>"text/html"}, "Hello Rack"], @app.call({})
  end

  def test_X_RateLimit_Limit_header
    assert_equal 100, @middleware.call({})[1]['X-RateLimit-Limit']
  end
end
