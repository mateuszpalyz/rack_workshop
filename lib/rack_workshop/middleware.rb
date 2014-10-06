module RackWorkshop
  class Middleware
    def initialize(app, options = {})
      @app = app
      @options = options
    end

    def call(env)
      status, headers, response = @app.call env
      headers['X-RateLimit-Limit'] = @options[:limit]
      [status, headers, response]
    end
  end
end
