require "spec_helper"

describe Mongoid::Fields::Internal::Regexp do

  describe "#cast_on_read?" do

    let(:field) do
      described_class.instantiate(:test)
    end

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#eval_default" do

    context "when the default value is a proc" do

      let(:field) do
        described_class.instantiate(:test, default: ->{ /[^abc]/ })
      end

      it "returns the called proc" do
        field.eval_default(nil).should eq(/[^abc]/)
      end
    end

    context "when the default value is not a proc" do

      let(:field) do
        described_class.instantiate(:test, default: /[^abc]/)
      end

      it "returns the default value" do
        field.default_val.should eq(/[^abc]/)
      end
    end
  end

  describe "#deserialize" do

    let(:field) do
      described_class.instantiate(:test)
    end

    let(:value) do
      field.deserialize(/[^abc]/)
    end

    it "returns the provided value" do
      value.should eq(/[^abc]/)
    end
  end

  describe "#initialize" do

    let(:field) do
      described_class.instantiate(:test, type: Regexp, label: "test")
    end

    it "sets the name" do
      field.name.should eq(:test)
    end

    it "sets the label" do
      field.label.should eq("test")
    end

    it "sets the options" do
      field.options.should eq({ type: Regexp, label: "test" })
    end
  end

  describe ".option" do

    let(:options) do
      Mongoid::Fields.options
    end

    let(:handler) do
      proc {}
    end

    it "stores the custom option in the options hash" do
      options.expects(:[]=).with(:option, handler)
      Mongoid::Fields.option(:option, &handler)
    end
  end

  describe ".options" do

    it "returns a hash of custom options" do
      Mongoid::Fields.options.should be_a Hash
    end

    it "is memoized" do
      Mongoid::Fields.options.should
        equal(Mongoid::Fields.options)
    end
  end

  describe "#serialize" do

    let(:field) do
      described_class.instantiate(:test)
    end

    context "when providing a regex" do

      let(:value) do
        field.serialize(/[^abc]/)
      end

      it "returns the provided value" do
        value.should eq(/[^abc]/)
      end
    end

    context "when providing a string" do

      let(:value) do
        field.serialize("[^abc]")
      end

      it "returns the provided value as a regex" do
        value.should eq(/[^abc]/)
      end
    end
  end

  context "when persisting the value" do

    let(:person) do
      Person.create(pattern: /[^a]/)
    end

    it "saves the value to the database" do
      person.reload.pattern.should eq(/[^a]/)
    end
  end
end
