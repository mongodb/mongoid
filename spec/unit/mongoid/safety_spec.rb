require "spec_helper"

describe Mongoid::Safety do

  describe ".safely" do

    let(:proxy) do
      Person.safely
    end

    it "returns a safe proxy" do
      proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
    end

    it "proxies the class" do
      proxy.target.should == Person
    end
  end

  describe "#safely" do

    let(:person) do
      Person.new
    end

    let(:proxy) do
      person.safely
    end

    it "returns a safe proxy" do
      proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
    end

    it "proxies the document" do
      proxy.target.should == person
    end
  end
end
