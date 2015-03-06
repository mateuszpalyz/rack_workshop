$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'rack/test'
require 'timecop'
require 'rack_workshop/middleware'
require 'rack_workshop/simple_rack_app'
require 'dalli'

class RackTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @app ||= RackWorkshop::Middleware.new(SimpleRackApp.new, { limit: 100 })
  end

  def setup
    Timecop.freeze(Time.now)
  end

  def test_response
    get '/'
    assert last_response.ok?
  end

  def test_X_RateLimit_Limit_header
    get '/'
    assert_equal 100, last_response.header['X-RateLimit-Limit']
  end

  def test_X_RateLimit_Remaining_header
    3.times { get '/' }
    assert_equal 97, last_response.header['X-RateLimit-Remaining']
  end

  def test_exceeding_limit_header
    101.times { get '/' }
    assert_equal 429, last_response.status
    assert_equal 'Too many Requests', last_response.body
  end

  def test_limit_header
    get '/'
    assert_equal Time.now + 3600, last_response.header['X-RateLimit-Reset']
  end

  def test_limit_header_reset_after_one_hour
    101.times { get '/' }
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

  def test_rate_limiter_custom_client_identification
    @app = RackWorkshop::Middleware.new(SimpleRackApp.new, { limit: 100 }) { |env| Rack::Request.new(env).params['api_token'] }

    get '/', { 'api_token' => 'aaa' }
    assert_equal 99, last_response.header['X-RateLimit-Remaining']

    get '/', { 'api_token' => 'bbb' }
    assert_equal 99, last_response.header['X-RateLimit-Remaining']

    get '/', { 'api_token' => 'bbb' }
    assert_equal 98, last_response.header['X-RateLimit-Remaining']

    get '/', { 'api_token' => 'aaa' }
    assert_equal 98, last_response.header['X-RateLimit-Remaining']
  end

  def test_rate_limiter_when_block_returns_nil
    @app = RackWorkshop::Middleware.new(SimpleRackApp.new, { limit: 100 }) { nil }

    get '/', {}
    assert_nil last_response.header['X-RateLimit-Remaining']
  end

  def test_dalli_as_a_store_mechanism
    options = { :namespace => "app_v1", :compress => true }
    dc = Dalli::Client.new('localhost:11211', options)
    @app = RackWorkshop::Middleware.new(SimpleRackApp.new, { limit: 100, store: dc }) { |env| Rack::Request.new(env).params['api_token'] }

    get '/', { 'api_token' => 'aaa' }
    assert_equal 99, last_response.header['X-RateLimit-Remaining']

    get '/', { 'api_token' => 'bbb' }
    assert_equal 99, last_response.header['X-RateLimit-Remaining']

    get '/', { 'api_token' => 'bbb' }
    assert_equal 98, last_response.header['X-RateLimit-Remaining']
  end

  def teardown
    Timecop.return
    @app = nil
  end
end
