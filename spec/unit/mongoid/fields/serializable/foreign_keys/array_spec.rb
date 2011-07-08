require "spec_helper"

describe Mongoid::Fields::Serializable::ForeignKeys::Array do

  describe "#default" do

    let(:default) do
      [ "test" ]
    end

    let(:field) do
      described_class.new(
        :vals,
        :type => Array,
        :default => default,
        :identity => true
      )
    end

    it "dups the default value" do
      field.default.should_not equal(default)
    end

    it "returns the correct value" do
      field.default.should == default
    end
  end

  describe "#serialize" do

    context "when the array is object ids" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          :inverse_class_name => "Game",
          :name => :person,
          :relation => Mongoid::Relations::Referenced::In
        )
      end

      let(:field) do
        described_class.new(
          :vals,
          :type => Array,
          :default => [],
          :identity => true,
          :metadata => metadata
        )
      end

      context "when using object ids" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        it "performs conversion on the ids if strings" do
          field.serialize([object_id.to_s]).should == [object_id]
        end
      end

      context "when not using object ids" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        before do
          Person.identity :type => String
        end

        after do
          Person.identity :type => BSON::ObjectId
        end

        it "does not convert" do
          field.serialize([object_id.to_s]).should == [object_id.to_s]
        end
      end
    end
  end
end
