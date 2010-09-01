require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::In do

  let(:klass) do
    Mongoid::Relations::Builders::Embedded::In
  end

  describe "#build" do

    let(:parent) do
      stub
    end

    let(:object) do
      stub(:_parent => parent)
    end

    let(:metadata) do
      stub(:klass => Person, :name => :person)
    end

    let(:builder) do
      klass.new(metadata, object)
    end

    before do
      @document = builder.build
    end

    it "sets the parent as the document" do
      @document.should == parent
    end
  end
end
