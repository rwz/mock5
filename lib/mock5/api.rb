require "uri"
require "sinatra"
require "webmock"

module Mock5
  class Api
    attr_reader :endpoint, :app

    def initialize(endpoint=nil, &block)
      @app = Sinatra.new(&block)
      @endpoint = normalize_endpoint(endpoint)
    end

    def request_stub
      @request_stub ||= WebMock::RequestStub.new(:any, endpoint).tap{ |s| s.to_rack(app) }
    end

    private

    def normalize_endpoint(endpoint)
      case endpoint
      when nil
        /.*/
      when String
        normalize_string_endpoint(endpoint)
      when Regexp
        endpoint
      else
        raise ArgumentError, "Endpoint should be string or regexp"
      end
    end

    def normalize_string_endpoint(endpoint)
      uri = URI.parse(endpoint)

      if uri.scheme !~ /\Ahttps?/
        raise ArgumentError, "Endpoint should be a valid URL"
      elsif uri.path != ?/ && !uri.path.empty?
        raise ArgumentError, "Endpoint URL should not include path"
      end

      uri.path = ""
      endpoint = Regexp.escape(uri.to_s)

      Regexp.new("\\A#{endpoint}\/#{app_paths_regex}\\z")
    end

    def app_paths_regex
      regexes = app.routes.values.flatten.select{ |v| Regexp === v }
      paths = regexes.map{ |regex| regex.source[3..-3] }

      return ".*" if paths.empty?

      paths = paths.one?? paths.first : %{(?:#{paths.join("|")})}

      "#{paths}(?:\\?.*)?"
    end
  end
end
