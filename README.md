# Mock5
[![Gem Version](https://img.shields.io/gem/v/mock5.svg)][gem]
[![Build Status](https://img.shields.io/travis/rwz/mock5.svg)][travis]
[![Code Climate](https://img.shields.io/codeclimate/github/rwz/mock5.svg)][codeclimate]
[gem]: https://rubygems.org/gems/mock5
[travis]: http://travis-ci.org/rwz/mock5
[codeclimate]: https://codeclimate.com/github/rwz/mock5

Mock5 allows to mock external APIs with simple Sinatra Rack apps.

## Installation

Add this line to your application's Gemfile:

    gem "mock5"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mock5

## Usage

Say you're writing a nice wrapper around remote user management REST API.
You want your library to handle any unexpected situation aproppriately and
show a relevant error message, or schedule a retry some time later.

Obviously, you can't rely on a production API to test all this codepaths. You
probably want a way to emulate all this situations locally. Enter Mock5:

```ruby
# user registers successfully
SuccessfulRegistration = Mock5.mock("http://example.com") do
  post "/users" do
    MultiJson.dump(
      first_name: "Zapp",
      last_name: "Brannigan",
      email: "zapp@planetexpress.com"
    )
  end
end

# registration returns validation error
UnsuccessfulRegistration = Mock5.mock("http://example.com") do
  post "/users" do
    halt 406, MultiJson.dump(
      first_name: ["is too lame"],
      email: ["is not unique"]
    )
  end
end

# remote api is down for some reason
RegistrationUnavailable = Mock5.mock("http://example.com") do
  post "/users" do
    halt 503, "Service Unavailable"
  end
end

# remote api times takes long time to respond
RegistrationTimeout = Mock5.mock("http://example.com") do
  post "/users" do
    sleep 15
  end
end

describe MyApiWrapper do
  describe "successfull" do
    around do |example|
      Mock5.with_mounted(SuccessfulRegistration, &example)
    end

    it "allows user registration" do
      expect{ MyApiWrapper.register_user }.not_to raise_error
    end
  end

  describe "validation errors" do
    around do |example|
      Mock5.with_mounted(UnsuccessfulRegistration, &example)
    end

    it "raises a valiation error" do
      expect{ MyApiWrapper.register_user }.to raise_error(MyApiWrapper::ValidationError)
    end
  end

  describe "service is unavailable" do
    around do |example|
      Mock5.with_mounted(RegistrationUnavailable, &example)
    end

    it "raises a ServiceUnavailable error" do
      expect{ MyApiWrapper.register_user }.to raise_error(MyApiWrapper::ServiceUnavailable)
    end
  end

  describe "timeout" do
    around do |example|
      Mock5.with_mounted(RegistrationTimeout, &example)
    end

    it "raises timeout error" do
      expect{ MyApiWrapper.register_user }.to raise_error(Timeout::Error)
    end
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
