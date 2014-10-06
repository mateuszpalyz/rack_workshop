module RackWorkshop
  class Middleware
    def initialize(app, options = {})
      @app = app
      @options = options
      @calls_number = 0
    end

    def call(env)
      @calls_number += 1
      status, headers, response = @app.call env
      headers['X-RateLimit-Limit'] = @options[:limit]
      headers['X-RateLimit-Remaining'] = @options[:limit] - @calls_number
      [status, headers, response]
    end
  end
end
