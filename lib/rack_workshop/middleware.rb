module RackWorkshop
  class Middleware
    def initialize(app, options = {})
      @app = app
      @options = options
      @calls = {}
    end

    def call(env)
      @calls[env['REMOTE_ADDR']] ||= Hash.new(0)

      @calls[env['REMOTE_ADDR']]['timestamp'] = Time.now if @calls[env['REMOTE_ADDR']]['calls_number'] == 0

      if Time.now - @calls[env['REMOTE_ADDR']]['timestamp'] > (@options[:reset_in] || 3600)
        @calls[env['REMOTE_ADDR']]['timestamp'] = Time.now
        @calls[env['REMOTE_ADDR']]['calls_number'] = 0
      end

      @calls[env['REMOTE_ADDR']]['calls_number'] += 1
      if @calls[env['REMOTE_ADDR']]['calls_number'] > @options[:limit]
        [429, { 'Content-Type' => 'text/html' }, "Too many Requests"]
      else
        status, headers, response = @app.call env
        headers['X-RateLimit-Limit'] = @options[:limit]
        headers['X-RateLimit-Remaining'] = @options[:limit] - @calls[env['REMOTE_ADDR']]['calls_number']
        headers['X-RateLimit-Reset'] = @calls[env['REMOTE_ADDR']]['timestamp'] + 3600
        [status, headers, response]
      end
    end
  end
end
