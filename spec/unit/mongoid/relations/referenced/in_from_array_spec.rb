require "spec_helper"

describe Mongoid::Relations::Referenced::InFromArray do

  let(:klass) do
    Mongoid::Relations::Referenced::InFromArray
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::InFromArray
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    it "returns the embedded in builder" do
      klass.builder(metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe ".macro" do

    it "returns referenced_in_from_array" do
      klass.macro.should == :referenced_in_from_array
    end
  end
end
