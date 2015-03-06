$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'rack/test'
require 'timecop'
require 'rack_workshop/middleware'
require 'rack_workshop/simple_rack_app'

class RackTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @app ||= RackWorkshop::Middleware.new(SimpleRackApp.new, { limit: 100 })
  end

  def setup
    Timecop.freeze(Time.now)
    get '/'
  end

  def test_response
    assert last_response.ok?
  end

  def test_X_RateLimit_Limit_header
    assert_equal 100, last_response.header['X-RateLimit-Limit']
  end

  def test_X_RateLimit_Remaining_header
    3.times { get '/' }
    assert_equal 96, last_response.header['X-RateLimit-Remaining']
  end

  def test_exceeding_limit_header
    100.times { get '/' }
    assert_equal 429, last_response.status
    assert_equal 'Too many Requests', last_response.body
  end

  def test_limit_header
    assert_equal Time.now + 3600, last_response.header['X-RateLimit-Reset']
  end

  def test_limit_header_reset_after_one_hour
    100.times { get '/' }
    assert_equal 429, last_response.status
    Timecop.freeze(Time.now + 3601)
    get '/'
    assert last_response.ok?
  end

  def test_separate_limit_for_each_client
    3.times { get '/', {}, 'REMOTE_ADDR' => '10.0.0.1' }
    assert_equal 97, last_response.header['X-RateLimit-Remaining']
    get '/', {}, 'REMOTE_ADDR' => '10.0.0.2'
    assert_equal 99, last_response.header['X-RateLimit-Remaining']
  end

  def teardown
    Timecop.return
  end
end
