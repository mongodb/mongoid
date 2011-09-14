require "spec_helper"

describe Mongoid::Fields::Serializable::Localized do

  let(:field) do
    described_class.instantiate(:description, :localize => true)
  end

  context "when no default is provided" do

    it "defaults to an empty hash" do
      field.default.should eq({})
    end
  end

  describe "#deserialize" do

    context "when no locale is defined" do

      let(:value) do
        field.deserialize({ "en" => "This is a test" })
      end

      it "returns the string from the default locale" do
        value.should eq("This is a test")
      end
    end

    context "when a locale is provided" do

      before do
        ::I18n.locale = :de
      end

      after do
        ::I18n.locale = :en
      end

      let(:value) do
        field.deserialize({ "de" => "This is a test" })
      end

      it "returns the string from the set locale" do
        value.should eq("This is a test")
      end
    end
  end

  describe "#serialize" do

    context "when no locale is defined" do

      let(:value) do
        field.serialize("This is a test")
      end

      it "returns the string in the default locale" do
        value.should eq({ "en" => "This is a test" })
      end
    end

    context "when a locale is provided" do

      before do
        ::I18n.locale = :de
      end

      after do
        ::I18n.locale = :en
      end

      let(:value) do
        field.serialize("This is a test")
      end

      it "returns the string in the set locale" do
        value.should eq({ "de" => "This is a test" })
      end
    end
  end
end
