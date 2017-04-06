require "spec_helper"

describe Mongoid::Association::Embedded::EmbeddedIn::Builder do

  describe "#build" do

    let(:object) do
      double
    end

    let(:base) do
      double
    end

    let(:association) do
      double(klass: Person, name: :person)
    end

    context "when a document is provided" do

      let(:builder) do
        described_class.new(base, association, object)
      end

      let(:document) do
        builder.build
      end

      it "returns the document" do
        expect(document).to eq(object)
      end
    end
  end
end
