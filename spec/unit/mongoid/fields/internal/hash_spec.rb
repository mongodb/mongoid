require "spec_helper"

describe Mongoid::Fields::Internal::Hash do

  let(:field) do
    described_class.instantiate(:test, :type => Hash)
  end

  describe "#cast_on_read?" do

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#eval_default" do

    context "when the default is a proc" do

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Hash,
          :default => lambda { { "field" => "value" } }
        )
      end

      it "calls the proc" do
        field.eval_default(nil).should eq({ "field" => "value" })
      end
    end

    context "when the default is a hash" do

      let(:default) do
        { "field" => "value" }
      end

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Hash,
          :default => default
        )
      end

      it "returns the correct value" do
        field.eval_default(nil).should eq(default)
      end

      it "returns a duped hash" do
        field.eval_default(nil).should_not equal(default)
      end
    end
    
    context "sorted is true" do
      
      let(:sorted_field) do
        { "parentA" => {"childA" => "value1", "childB" => "value2"}, "parentB" => {"childC" => "value3", "childD" => "value4"} }
      end
      
      context "when the default is a proc" do

        let(:field) do
          described_class.instantiate(
            :test,
            :type => Hash,
            :default => lambda { { "parentB" => {"childD" => "value4", "childC" => "value3"}, "parentA" => {"childB" => "value2", "childA" => "value1"} } },
            :sorted => true
          )
        end

        # Required since ruby will consider the 2 hashes to be equal, but mongodb won't
        it "calls the proc and sorts the result" do
          field.eval_default(nil).keys.should eq(sorted_field.keys)
        end

        it "calls the proc and sorts the children of the result" do
          field.eval_default(nil)["parentA"].keys.should eq(sorted_field["parentA"].keys)
        end
      end
      
      context "when the default is a hash and sorted is true" do

        let(:default) do
          { "parentB" => {"childD" => "value4", "childC" => "value3"}, "parentA" => {"childB" => "value2", "childA" => "value1"} }
        end

        let(:field) do
          described_class.instantiate(
            :test,
            :type => Hash,
            :default => default,
            :sorted => true
          )
        end

        # Required since ruby will consider the 2 hashes to be equal, but mongodb won't
        it "calls the proc and sorts the result" do
          field.eval_default(nil).keys.should eq(sorted_field.keys)
        end

        it "calls the proc and sorts the children of the result" do
          field.eval_default(nil)["parentA"].keys.should eq(sorted_field["parentA"].keys)
        end
        
        it "returns a duped hash" do
          field.eval_default(nil).should_not equal(default)
        end
      end
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "returns the value" do
        field.selection({ "field" => "value" }).should eq({ "field" => "value" })
      end
    end
    
    context "when providing an unsorted hash, and sorted option is true" do
      
      let(:field) do
        described_class.instantiate(
          :test,
          :type => Hash,
          :sorted => true
        )
      end

      let(:object) do
        { "parentB" => {"childD" => "value4", "childC" => "value3"}, "parentA" => {"childB" => "value2", "childA" => "value1"} }
      end
      
      let(:serialized_object) do
        { "parentA" => {"childA" => "value1", "childB" => "value2"}, "parentB" => {"childC" => "value3", "childD" => "value4"} }
      end
      
      # Required since ruby will consider the 2 hashes to be equal, but mongodb won't
      it "returns the hash with its keys sorted" do
        field.selection(object).keys.should eq(serialized_object.keys)
      end
      
      it "returns the hash with its children's keys sorted" do
        field.selection(object)["parentA"].keys.should eq(serialized_object["parentA"].keys)
      end
    end
  end

  describe "#serialize" do

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end

    context "when the value is a hash" do

      it "returns the hash" do
        field.serialize({ "field" => "value" }).should eq({ "field" => "value" })
      end
    end
    
    context "when the value is a hash, and sorted option is true" do
      
      let(:field) do
        described_class.instantiate(
          :test,
          :type => Hash,
          :sorted => true
        )
      end

      let(:object) do
        { "parentB" => {"childD" => "value4", "childC" => "value3"}, "parentA" => {"childB" => "value2", "childA" => "value1"} }
      end
      
      let(:serialized_object) do
        { "parentA" => {"childA" => "value1", "childB" => "value2"}, "parentB" => {"childC" => "value3", "childD" => "value4"} }
      end
      
      # Required since ruby will consider the 2 hashes to be equal, but mongodb won't
      it "returns the hash with its keys sorted" do
        field.serialize(object).keys.should eq(serialized_object.keys)
      end
      
      it "returns the hash with its children's keys sorted" do
        field.serialize(object)["parentA"].keys.should eq(serialized_object["parentA"].keys)
      end
    end
  end
end
