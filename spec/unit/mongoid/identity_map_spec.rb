require "spec_helper"

describe Mongoid::IdentityMap do

  let(:identity_map) do
    described_class.new
  end

  describe "#clear" do

    before do
      identity_map.set(Person.new)
    end

    let!(:clear) do
      identity_map.clear
    end

    it "empties the identity map" do
      identity_map.should be_empty
    end

    it "returns an empty hash" do
      clear.should eq({})
    end
  end

  describe ".clear" do

    before do
      described_class.set(Person.new)
    end

    let!(:clear) do
      described_class.clear
    end

    it "returns an empty hash" do
      clear.should eq({})
    end
  end

  describe "#get" do

    let(:document) do
      Person.new
    end

    context "when the document exists in the identity map" do

      before do
        identity_map.set(document)
      end

      let(:get) do
        identity_map.get(document.id)
      end

      it "returns the matching document" do
        get.should eq(document)
      end
    end

    context "when the document does not exist in the map" do

      let(:get) do
        identity_map.get(document.id)
      end

      it "returns nil" do
        get.should be_nil
      end
    end
  end

  describe ".get" do

    let(:document) do
      Person.new
    end

    context "when the document exists in the identity map" do

      before do
        described_class.set(document)
      end

      let(:get) do
        described_class.get(document.id)
      end

      it "returns the matching document" do
        get.should eq(document)
      end
    end

    context "when the document does not exist in the map" do

      let(:get) do
        described_class.get(document.id)
      end

      it "returns nil" do
        get.should be_nil
      end
    end
  end

  describe "#set" do

    context "when setting a document" do

      let(:document) do
        Person.new
      end

      let!(:set) do
        identity_map.set(document)
      end

      it "puts the object in the identity map" do
        identity_map.get(document.id).should eq(document)
      end

      it "returns the document" do
        set.should eq(document)
      end
    end

    context "when setting nil" do

      let!(:set) do
        identity_map.set(nil)
      end

      it "places nothing in the map" do
        identity_map.should be_empty
      end

      it "returns nil" do
        set.should be_nil
      end
    end
  end

  describe ".set" do

    context "when setting a document" do

      let(:document) do
        Person.new
      end

      let!(:set) do
        described_class.set(document)
      end

      it "puts the object in the identity map" do
        described_class.get(document.id).should eq(document)
      end

      it "returns the document" do
        set.should eq(document)
      end
    end

    context "when setting nil" do

      let!(:set) do
        described_class.set(nil)
      end

      it "returns nil" do
        set.should be_nil
      end
    end
  end

  context "when accessing hash methods directly" do

    Hash.public_instance_methods(false).each do |method|

      it "can access #{method} at the class level" do
        described_class.should respond_to(method)
      end
    end
  end

  context "when executing in a fiber" do

    if RUBY_VERSION.to_f >= 1.9

      describe "#.get" do

        let(:document) do
          Person.new
        end

        let(:fiber) do
          Fiber.new do
            described_class.set(document)
            described_class.get(document.id).should eq(document)
          end
        end

        it "gets the object from the identity map" do
          fiber.resume
        end
      end
    end
  end
end
