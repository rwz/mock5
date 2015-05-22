require "mock5"

describe Mock5 do
  describe ".mock" do
    it "creates an Api" do
      expect(described_class::Api).to receive(:new).with(/foo/).and_yield
      described_class.mock /foo/ do
        # mock definition goes here
      end
    end

    it "returns an Api" do
      expect(described_class.mock).to be_kind_of(described_class::Api)
    end
  end

  describe "API mgmt" do
    before do
      described_class.instance_exec do
        if instance_variable_defined?(:@_mounted_apis)
          remove_instance_variable :@_mounted_apis
        end
      end
    end

    let(:mounted_apis){ described_class.mounted_apis }
    let(:mounted_apis_qty){ mounted_apis.size }
    let(:api){ described_class.mock }
    let(:another_api){ described_class.mock }

    describe ".mount" do
      it "raises ArgumentError when passed an invalid argument" do
        action = ->{ described_class.mount nil }
        message = "expected an instance of Mock5::Api"
        expect(&action).to raise_error(ArgumentError, message)
      end
      it "mounts an api" do
        described_class.mount api
        expect(mounted_apis).to include(api)
      end

      it "mounts an api only once" do
        10.times{ described_class.mount api }
        expect(mounted_apis_qty).to eq(1)
      end

      it "mounts several APIs at once" do
        described_class.mount api, another_api
        expect(mounted_apis).to include(api)
        expect(mounted_apis).to include(another_api)
      end

      it "returns the list of mounted apis" do
        expect(described_class.mount(api)).to eq([api].to_set)
        expect(described_class.mount(api, another_api)).to eq([another_api].to_set)
      end
    end

    describe ".unmount" do
      before{ described_class.mount api }

      it "unmounts mounted api" do
        described_class.unmount api
        expect(mounted_apis).to be_empty
      end

      it "unmounts api only once" do
        10.times{ described_class.unmount api }
        expect(mounted_apis).to be_empty
      end

      it "unmounts several APIs at once" do
        described_class.mount another_api
        expect(mounted_apis_qty).to eq(2)
        described_class.unmount api, another_api
        expect(mounted_apis).to be_empty
      end

      it "only unmount specified api" do
        described_class.mount another_api
        described_class.unmount api
        expect(mounted_apis).to include(another_api)
      end

      it "returns the list of unmounted apis" do
        expect(described_class.unmount(another_api)).to be_empty
        expect(described_class.unmount(api, another_api)).to eq([api].to_set)
      end
    end

    describe ".unmount_all!" do
      before do
        3.times{ described_class.mount described_class.mock }
      end

      it "unmounts all currently mounted apis" do
        expect(mounted_apis_qty).to eq(3)
        described_class.unmount_all!
        expect(mounted_apis).to be_empty
      end

      it "has .reset! alias" do
        expect(mounted_apis_qty).to eq(3)
        described_class.reset!
        expect(mounted_apis).to be_empty
      end
    end

    describe ".mounted?" do
      before{ described_class.mount api }

      it "returns true if api is currently mounted" do
        expect(described_class.mounted?(api)).to be_truthy
      end

      it "returns false if api is currently not mounted" do
        expect(described_class.mounted?(another_api)).to be_falsy
      end

      it "returns true only when ALL api are mounted" do
        action = ->{ described_class.mount another_api }
        result = ->{ described_class.mounted? api, another_api }
        expect(&action).to change(&result).from(false).to(true)
      end
    end

    describe ".with_mounted" do
      it "temporary mounts an API" do
        action = -> do
          described_class.with_mounted api do
            expect(mounted_apis).to include(api)
          end
        end

        expect(mounted_apis).to be_empty
        expect(&action).not_to change(mounted_apis, :empty?)
      end

      it "doesn't unmount api, that was mounted before" do
        described_class.mount api

        described_class.with_mounted api, another_api do
          expect(mounted_apis).to include(another_api)
        end

        expect(mounted_apis).to include(api)
        expect(mounted_apis).not_to include(another_api)
      end
    end

    describe "stubbing" do
      def get(url)
        Net::HTTP.get(URI(url))
      end

      def post(url, params={})
        Net::HTTP.post_form(URI(url), params).body
      end

      let(:api) do
        described_class.mock "http://example.com" do
          get "/index.html" do
            "index.html"
          end

          post "/submit/here" do
            "submit"
          end
        end
      end

      let(:another_api) do
        described_class.mock "http://example.com" do
          post "/foo/:foo" do
            params["foo"]
          end

          get "/bar/:bar" do
            params["bar"]
          end
        end
      end

      context "#mount" do
        before{ described_class.mount api, another_api }

        it "stubs remote apis" do
          expect(get("http://example.com/index.html?foo=bar")).to eq("index.html")
          expect(post("http://example.com/submit/here?foo=bar")).to eq("submit")
          expect(post("http://example.com/foo/bar?fizz=buzz")).to eq("bar")
          expect(get("http://example.com/bar/foo")).to eq("foo")
        end
      end

      context "#with_mounted" do
        around do |example|
          described_class.with_mounted api, another_api, &example
        end

        it "stubs remote apis" do
          expect(get("http://example.com/index.html?foo=bar")).to eq("index.html")
          expect(post("http://example.com/submit/here?foo=bar")).to eq("submit")
          expect(post("http://example.com/foo/bar?fizz=buzz")).to eq("bar")
          expect(get("http://example.com/bar/foo")).to eq("foo")
        end
      end
    end
  end
end
