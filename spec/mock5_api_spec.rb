require "mock5/api"
require "rack/mock"

describe Mock5::Api do
  describe "#endpoint" do
    it "matches all by default" do
      expect(subject.endpoint).to eq(/.*/)
    end

    it "can be specified as a regex" do
      api = described_class.new(/foo/)
      expect(api.endpoint).to eq(/foo/)
    end

    it "can be specified as a valid url without path" do
      api = described_class.new("http://example.com")
      expect(api.endpoint).to eq(%r(\Ahttp://example\.com/.*\z))
    end

    it "can not be specified as a valid url with path" do
      expect{ described_class.new("http://example.com/foo") }
        .to raise_error(ArgumentError, "Endpoint URL should not include path")
    end

    it "can not be specified as an invalid url string" do
      expect{ described_class.new("foo") }
        .to raise_error(ArgumentError, "Endpoint should be a valid URL")
    end

    it "can not be specified by anything else" do
      [false, :foo, 123].each do |invalid_endpoint|
        expect{ described_class.new(invalid_endpoint) }
          .to raise_error(ArgumentError, "Endpoint should be string or regexp")
      end
    end
  end

  describe "#app" do
    it "is a Class" do
      expect(subject.app).to be_kind_of(Class)
    end

    it "is a Sinatra Rack app" do
      expect(subject.app.superclass).to eq(Sinatra::Base)
    end

    describe "configuration" do
      subject do
        described_class.new do
          get "/hello/:what" do |what|
            "Hello, #{what.capitalize}"
          end
        end
      end

      let(:server){ Rack::Server.new(app: subject.app) }
      let(:mock_request){ Rack::MockRequest.new(server.app) }

      it "can be configures by a block" do
        response = mock_request.get("/hello/world")
        expect(response.body.to_s).to eq("Hello, World")
      end
    end
  end

  describe "#request_stub" do
    it "returns a request stub" do
      expect(subject.request_stub).to be_kind_of(WebMock::RequestStub)
    end
  end
end
