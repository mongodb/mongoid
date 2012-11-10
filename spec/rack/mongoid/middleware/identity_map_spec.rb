require "spec_helper"

describe "Rack::Mongoid::Middleware::IdentityMap" do

  before(:all) do
    require "rack/mongoid"
  end

  let(:app) do
    stub
  end

  let(:env) do
    stub
  end

  let(:klass) do
    Rack::Mongoid::Middleware::IdentityMap
  end

  describe "#call" do

    let(:middleware) do
      klass.new(app)
    end

    let(:document) do
      Person.new
    end

    before do
      Mongoid::IdentityMap.set(document)
    end

    describe "when no exception is raised" do

      before do
        app.should_receive(:call).with(env).and_return([])
      end

      let!(:result) do
        middleware.call(env)
      end

      it "returns the call with the body proxy" do
        result.should eq([])
      end

      it "clears out the identity map" do
        Mongoid::Threaded.identity_map.should be_empty
      end
    end

    describe "when an exception is raised" do

      before do
        app.should_receive(:call).with(env).and_raise(RuntimeError)
      end

      let!(:result) do
        begin
          middleware.call(env)
        rescue
        end
      end

      it "clears out the identity map" do
        Mongoid::Threaded.identity_map.should be_empty
      end
    end
  end
end
