# frozen_string_literal: true

require 'rack'
require 'ipinfo'

class IPinfoMiddleware
    def initialize(app, cache_options = {})
        @app = app
        @token = cache_options.fetch(:token, nil)
        @ipinfo = IPinfo.create(@token, cache_options)
        @filter = cache_options.fetch(:filter, nil)
    end

    def call(env)
        env['called'] = 'yes'
        request = Rack::Request.new(env)

        filtered = if @filter.nil?
                       is_bot(request)
                   else
                       @filter.call(request)
                   end

        if filtered
            env['ipinfo'] = nil
        else
            cf_ip_header = request.env["HTTP_CF_CONNECTING_IP"]
            ip = request.ip
            ip = cf_ip_header unless cf_ip_header.nil?
            env['ipinfo'] = @ipinfo.details(ip)
        end

        @app.call(env)
    end

    private

    def is_bot(request)
        if request.user_agent
            user_agent = request.user_agent.downcase
            user_agent.include?('bot') || user_agent.include?('spider')
        else
            false
        end
    end
end
