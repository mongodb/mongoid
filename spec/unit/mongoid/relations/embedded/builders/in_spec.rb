
require "spec_helper"

describe Mongoid::Relations::Embedded::Builders::In do

  let(:klass) do
    Mongoid::Relations::Embedded::Builders::In
  end

  describe "#build" do

    let(:parent) do
      stub
    end

    let(:metadata) do
      stub(:klass => Person, :name => :person)
    end

    let(:builder) do
      klass.new(metadata, nil, parent)
    end

    before do
      @document = builder.build
    end

    it "sets the parent as the document" do
      @document.should == parent
    end
  end
end
