require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::In do

  let(:klass) do
    Mongoid::Relations::Builders::Embedded::In
  end

  describe "#build" do

    let(:object) do
      stub
    end

    let(:metadata) do
      stub(:klass => Person, :name => :person)
    end

    context "when a document is provided" do

      let(:builder) do
        klass.new(metadata, object)
      end

      let(:document) do
        builder.build
      end

      it "returns the document" do
        document.should == object
      end
    end

    context "when attributes are provided" do

      let(:builder) do
        klass.new(metadata, { :title => "Sir" })
      end

      let(:document) do
        builder.build
      end

      it "returns a new document" do
        document.should be_a_kind_of(Person)
      end

      it "sets the attributes on the document" do
        document.title.should == "Sir"
      end
    end
  end
end
