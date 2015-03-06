module RackWorkshop
  class Middleware
    def initialize(app, options = {}, &block)
      @app = app
      @options = options
      @calls = {}
      @block = block
    end

    def call(env)
      set_client_identifier(env)

      if @client_identifier
        @calls[@client_identifier] ||= Hash.new(0)

        set_timestamp_for_first_call(env)
        reset_limit(env) if reset_limit?(env)
        increase_calls_number(env)

        limit_exceeded?(env) ? bad_response : good_response(env)
      else
        basic_response(env)
      end
    end

    def set_client_identifier(env)
      @client_identifier = @block ? custom_auth(env) : env['REMOTE_ADDR']
    end

    def custom_auth(env)
      @block.call(env)
    end

    def limit_exceeded?(env)
      @calls[@client_identifier]['calls_number'] > @options[:limit]
    end

    def reset_limit?(env)
      Time.now - @calls[@client_identifier]['timestamp'] > (@options[:reset_in] || 3600)
    end

    def reset_limit(env)
      @calls[@client_identifier]['timestamp'] = Time.now
      @calls[@client_identifier]['calls_number'] = 0
    end

    def bad_response
      [429, { 'Content-Type' => 'text/html' }, "Too many Requests"]
    end

    def good_response(env)
      status, headers, response = basic_response env
      headers['X-RateLimit-Limit'] = @options[:limit]
      headers['X-RateLimit-Remaining'] = @options[:limit] - @calls[@client_identifier]['calls_number']
      headers['X-RateLimit-Reset'] = @calls[@client_identifier]['timestamp'] + 3600
      [status, headers, response]
    end

    def basic_response(env)
      @app.call env
    end

    def increase_calls_number(env)
      @calls[@client_identifier]['calls_number'] += 1
    end

    def set_timestamp_for_first_call(env)
      @calls[@client_identifier]['timestamp'] = Time.now if @calls[@client_identifier]['calls_number'] == 0
    end
  end
end
