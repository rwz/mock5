require "set"

# The main module of the gem, exposing all API management methods.
# Can be included into class.
module Mock5
  extend self

  autoload :VERSION, "mock5/version"
  autoload :Api, "mock5/api"

  # Returns a set of currently mounted APIs
  #
  # @return [Set] a list of currently mounted APIs
  def mounted_apis
    @_mounted_apis ||= Set.new
  end

  # Generates a new API
  #
  # @example
  #   my_mock_api = Mock5.mock("http://example.com") do
  #     get "posts" do
  #       [
  #         {id: 1, body: "a post body"},
  #         {id: 2, body: "another post body"}
  #       ].to_json
  #     end
  #
  #     post "posts" do
  #       halt 201, "The post was created successfully"
  #     end
  #   end
  #
  # @param endpoint [String] a url of the API service endpoint to mock.
  #   Should only include hostname and schema.
  #
  # @yield a block to define behavior using Sinatra API
  #
  # @return [Mock5::Api] a mountable API object
  def mock(endpoint=nil, &block)
    Api.new(endpoint, &block)
  end

  # Mounts given list of APIs. Returns a list of APIs that were actually
  # mounted. The APIs that were already mounted when the method is called
  # are not included in the return value.
  #
  # @param apis [Enum #to_set] a list of APIs to mount
  #
  # @return [Set] a list of APIs actually mounted
  def mount(*apis)
    apis.to_set.subtract(mounted_apis).each do |api|
      check_api api
      mounted_apis.add api
      registry.register_request_stub api.request_stub
    end
  end

  # Unmount given APIs. Returns only the list of APIs that were actually
  # unmounted. If the API wasn't mounted when the method is called, it won't be
  # included in the return value.
  #
  # @param apis [Enum #to_set] a list of APIs to unmount
  #
  # @return [Set] a list of APIs actually unmounted
  def unmount(*apis)
    mounted_apis.intersection(apis).each do |api|
      mounted_apis.delete api
      if registry.request_stubs.include?(api.request_stub)
        registry.remove_request_stub api.request_stub
      end
    end
  end

  # Returns true if all given APIs are mounted. false otherwise.
  #
  # @param apis [Enum #to_set] a list of APIs to check
  #
  # @return [Boolean] true if all given APIs are mounted, false otherwise
  def mounted?(*apis)
    apis.to_set.subset?(mounted_apis)
  end

  # Mounts a list of given APIs, executes block and then unmounts them back.
  # Useful for wrapping around RSpec tests. It only unmounts APIs that were
  # not mounted before. Any API that was mounted before the method was
  # called remains mounted.
  #
  # @example
  #   my_api = Mock5.mock("http://example.com") do
  #     get "index.html" do
  #       "<h1>Hello world!</h1>"
  #     end
  #   end
  #
  #   another_api = Mock5.mock("http://foobar.com") do
  #     get "hello/:what" do
  #       "<h1>Hello #{params["what"]}</h1>"
  #     end
  #   end
  #
  #   Mock5.with_mounted my_api, another_api do
  #     Net::HTTP.get("example.com", "/index.html") # => "<h1>Hello world!</h1>"
  #     Net::HTTP.get("foobar.com", "/hello/bar") # => "<h1>Hello, bar</h1>"
  #   end
  #
  # @param apis [Enum #to_set] a list of APIs to mount before executing the
  #   block
  #
  # @yield the block to execute with given APIs being mounted
  def with_mounted(*apis)
    mounted = mount(*apis)
    yield
  ensure
    unmount *mounted
  end

  # Unmounts all currently mounted APIs and returns them
  #
  # @return [Set] a list of unmounted APIs
  def unmount_all!
    unmount *mounted_apis
  end

  alias_method :reset!, :unmount_all!

  private

  def registry
    WebMock::StubRegistry.instance
  end

  def check_api(api)
    fail ArgumentError, "expected an instance of Mock5::Api" unless Api === api
  end
end
