require "mock5/version"
require "mock5/api"
require "set"

module Mock5
  extend self

  def mounted_apis
    @_mounted_apis ||= Set.new
  end

  def mock(*args, &block)
    Api.new(*args, &block)
  end

  def mount(*apis)
    (apis.to_set - mounted_apis).each do |api|
      mounted_apis.add api
      registry.register_request_stub api.request_stub
    end
  end

  def unmount(*apis)
    (mounted_apis & apis).each do |api|
      mounted_apis.delete api
      registry.remove_request_stub api.request_stub
    end
  end

  def mounted?(*apis)
    apis.to_set.subset?(mounted_apis)
  end

  def with_mounted(*apis)
    mounted = mount(*apis)
    yield
  ensure
    unmount *mounted
  end

  def unmount_all!
    unmount *mounted_apis
  end

  alias_method :reset!, :unmount_all!

  private

  def registry
    WebMock::StubRegistry.instance
  end
end
