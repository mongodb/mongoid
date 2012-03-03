require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::In do

  describe "#build" do

    let(:object) do
      stub
    end

    let(:base) do
      stub
    end

    let(:metadata) do
      stub(klass: Person, name: :person)
    end

    context "when a document is provided" do

      let(:builder) do
        described_class.new(base, metadata, object)
      end

      let(:document) do
        builder.build
      end

      it "returns the document" do
        document.should eq(object)
      end
    end
  end
end
