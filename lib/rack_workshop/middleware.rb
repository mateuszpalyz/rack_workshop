module RackWorkshop
  class Middleware
    def initialize(app, options = {})
      @app = app
      @options = options
      @calls = {}
    end

    def call(env)
      @calls[env['REMOTE_ADDR']] ||= Hash.new(0)

      set_timestamp_for_first_call(env)
      reset_limit(env) if reset_limit?(env)
      increase_calls_number(env)

      limit_exceeded?(env) ? bad_response : good_response(env)
    end

    def limit_exceeded?(env)
      @calls[env['REMOTE_ADDR']]['calls_number'] > @options[:limit]
    end

    def reset_limit?(env)
      Time.now - @calls[env['REMOTE_ADDR']]['timestamp'] > (@options[:reset_in] || 3600)
    end

    def reset_limit(env)
      @calls[env['REMOTE_ADDR']]['timestamp'] = Time.now
      @calls[env['REMOTE_ADDR']]['calls_number'] = 0
    end

    def bad_response
      [429, { 'Content-Type' => 'text/html' }, "Too many Requests"]
    end

    def good_response(env)
      status, headers, response = @app.call env
      headers['X-RateLimit-Limit'] = @options[:limit]
      headers['X-RateLimit-Remaining'] = @options[:limit] - @calls[env['REMOTE_ADDR']]['calls_number']
      headers['X-RateLimit-Reset'] = @calls[env['REMOTE_ADDR']]['timestamp'] + 3600
      [status, headers, response]
    end

    def increase_calls_number(env)
      @calls[env['REMOTE_ADDR']]['calls_number'] += 1
    end

    def set_timestamp_for_first_call(env)
      @calls[env['REMOTE_ADDR']]['timestamp'] = Time.now if @calls[env['REMOTE_ADDR']]['calls_number'] == 0
    end
  end
end
