require "uri"
require "sinatra"
require "webmock"

module Mock5
  # A class representing an API mock
  class Api

    # @return [Sinatra::Base] a Sinatra app mocking the API
    attr_reader :app

    # @return [Regexp] a regexp to match the API request urls
    attr_reader :endpoint

    # Returns an instance of +Mock5::Api+
    #
    # @example
    #   my_mock_api = Mock5::Api.new("http://example.com") do
    #     get "posts" do
    #       [
    #         {id: 1, body: "a posy body"},
    #         {id: 2, body: "another post body"}
    #       ].to_json
    #     end
    #
    #     post "posts" do
    #       halt 201, "The post was created successfully"
    #     end
    #   end
    #
    # @param endpoint [String, Regexp] a url of the API service to
    #   endpoint to mock. Can only contain schema and hostname, path
    #   should be empty.
    #
    # @yield a block passed to Sinatra to initialize an app
    #
    # @return [Mock5::Api]
    def initialize(endpoint=nil, &block)
      @app = Sinatra.new(&block)
      @endpoint = normalize_endpoint(endpoint)
    end

    # Returns webmock request stub built with Sinatra app and enpoint url
    #
    # @return [WebMock::RequestStub]
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
