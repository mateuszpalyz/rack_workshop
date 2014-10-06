require 'minitest/autorun'
require 'rack/test'
require '../lib/rack_workshop/middleware'

class RackTest < Minitest::Test
  include Rack::Test::Methods

  def app
    rack_app = lambda { |env| [200, { 'Content-Type' => 'text/html' }, "Hello Rack"] }
    Middleware.new(rack_app, { limit: 100 })
  end

  def setup
    get '/'
  end

  def test_response
    assert last_response.ok?
  end

  def test_X_RateLimit_Limit_header
    assert_equal 100, last_response.header['X-RateLimit-Limit']
  end
end
