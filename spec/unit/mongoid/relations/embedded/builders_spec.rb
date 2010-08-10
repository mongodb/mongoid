require "spec_helper"

describe Mongoid::Relations::Embedded::Builders do

  let(:klass) do
    Class.new do
      include Mongoid::Relations
    end
  end

  let(:relation) do
    Mongoid::Relations::Embedded::One
  end

  describe ".builder" do

    let(:document) do
      klass.new
    end

    before do
      document.instance_variable_set(:@attributes, {})
      klass.builder("name")
    end

    it "defines a build_* method" do
      document.should respond_to(:build_name)
    end

    it "returns self" do
      klass.builder("name").should == klass
    end

    context "defined methods" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          :name => :name,
          :relation => relation
        )
      end

      before do
        klass.getter("name", metadata).setter("name", metadata)
      end

      describe "#build_\{relation\}" do

        before do
          @relation = document.build_name(:first_name => "Obie")
        end

        it "returns a new document" do
          @relation.should be_a_kind_of(Name)
        end

        it "sets the attributes on the document" do
          @relation.first_name.should == "Obie"
        end
      end
    end
  end

  describe ".creator" do

    let(:document) do
      klass.new
    end

    before do
      document.instance_variable_set(:@attributes, {})
      klass.creator("name")
    end

    it "defines a create_* method" do
      document.should respond_to(:create_name)
    end

    it "returns self" do
      klass.creator("name").should == klass
    end

    context "defined methods" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          :name => :name,
          :relation => relation
        )
      end

      before do
        klass.getter("name", metadata).setter("name", metadata)
      end

      describe "#create_\{relation\}" do

        before do
          Name.any_instance.expects(:save).returns(true)
          @relation = document.create_name(:first_name => "Obie")
        end

        it "returns a newly saved document" do
          @relation.should be_a_kind_of(Name)
        end

        it "sets the attributes on the document" do
          @relation.first_name.should == "Obie"
        end
      end
    end
  end
end
