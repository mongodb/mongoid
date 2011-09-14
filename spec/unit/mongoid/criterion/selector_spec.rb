require "spec_helper"
require 'mongoid/criterion/selector'

describe Mongoid::Criterion::Selector do

  let(:field) do
    stub(:type => Integer, :localized? => false)
  end

  describe "#initialize" do

    let(:klass) do
      stub
    end

    before do
      klass.stubs(:fields).returns({})
    end

    it "stores the class" do
      Mongoid::Criterion::Selector.new(klass).klass.should == klass
    end
  end

  describe "#[]=" do

    let(:klass) do
      Class.new
    end

    let(:selector) do
      Mongoid::Criterion::Selector.new(klass)
    end

    it "should store the values provided" do
      klass.stubs(:fields).returns({})
      selector["age"] = 45
      selector["age"].should == 45
    end

    it "should typecast values when possible" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:serialize).with("45").returns(45)
      selector["age"] = "45"
      selector["age"].should == 45
    end

    it "should typecast complex conditions" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:serialize).with("45").returns(45)
      selector["age"] = { "$gt" => "45" }
      selector["age"].should == { "$gt" => 45 }
    end

    context "when the field is localized" do

      let(:selector) do
        described_class.new(Product)
      end

      context "when no locale is defined" do

        before do
          selector["description"] = "testing"
        end

        it "converts to dot notation with the default locale" do
          selector["description.en"].should eq("testing")
        end
      end

      context "when a locale is defined" do

        before do
          ::I18n.locale = :de
          selector["description"] = "testing"
        end

        after do
          ::I18n.locale = :en
        end

        it "converts to dot notation with the set locale" do
          selector["description.de"].should eq("testing")
        end
      end
    end
  end

  describe "#update" do

    let(:klass) do
      Class.new
    end

    let(:selector) do
      Mongoid::Criterion::Selector.new(klass)
    end

    it "should typecast values when possible" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:serialize).with("45").returns(45)
      selector.update({"age" => "45"})
      selector["age"].should == 45
    end
  end

  describe "#merge!" do

    let(:klass) do
      Class.new
    end

    let(:selector) do
      Mongoid::Criterion::Selector.new(klass)
    end

    it "should typecast values when possible" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:serialize).with("45").returns(45)
      selector.merge!({"age" => "45"})
      selector["age"].should == 45
    end
  end

  describe "#try_to_typecast" do

    let(:klass) do
      Class.new
    end

    let(:selector) do
      Mongoid::Criterion::Selector.new(klass)
    end

    context "when the key is not a declared field" do
      it "returns the value" do
        klass.stubs(:fields).returns({})
        selector.send(:try_to_typecast, "age", "45").should == "45"
      end
    end

    context "when the key is a declared field" do
      it "returns the typecast value" do
        field = stub_everything
        klass.stubs(:fields).returns({"age" => field})
        selector.expects(:typecast_value_for).with(field, "45")
        selector.send(:try_to_typecast, "age", "45")
      end
    end
  end

  describe "#typecast_value_for" do
    let(:field) { stub(:type => Integer) }
    let(:selector) { Mongoid::Criterion::Selector.allocate }

    context "when the value is simple" do
      it "should delegate to the field to typecast" do
        field.expects(:serialize).with("45")
        selector.send(:typecast_value_for, field, "45")
      end

      context "when the field is an array" do

        let(:field) { stub(:type => Array) }

        it "allows the simple value to be set" do
          Mongoid::Serialization.expects(:mongoize).with("007", String)
          selector.send(:typecast_value_for, field, "007")
        end
      end
    end

    context "when the value is a regex" do
      it "should return the regex unmodified" do
        field.expects(:serialize).never
        selector.send(:typecast_value_for, field, /Regex/)
      end
    end

    context "when the value is an array" do

      context "and the field type is array" do
        it "should let the field typecast the value" do
          field.stubs(:type).returns(Array)
          field.expects(:serialize).with([]).once
          selector.send(:typecast_value_for, field, [])
        end
      end

      context "and the field type is not array" do
        it "should typecast each value" do
          field.stubs(:type).returns(Integer)
          field.expects(:serialize).twice
          selector.send(:typecast_value_for, field, ["1", "2"])
        end
      end
    end

    context "when the value is a hash" do

      context "and the field type is not hash" do
        before { field.stubs(:type => Integer) }

        it "should not modify the original value" do
          value = {}
          value.expects(:dup).returns({})
          selector.send(:typecast_value_for, field, value)
        end

        context "when the hash is an $exists query" do

          it "should not typecast the hash" do
            value = {"$exists" => true}
            field.expects(:serialize).never
            selector.send(:typecast_value_for, field, value)
          end

          it "typecasts the value" do
            value = {"$exists" => "true"}
            Mongoid::Serialization.expects(:mongoize).with("true", Boolean)
            selector.send(:typecast_value_for, field, value)
          end
        end

        context "when the hash is a $size query" do

          it "should not typecast the hash" do
            value = {"$size" => 2}
            field.expects(:serialize).never
            selector.send(:typecast_value_for, field, value)
          end

          it "typecasts the value" do
            value = {"$size" => "2"}
            Mongoid::Serialization.expects(:mongoize).with("2", Integer)
            selector.send(:typecast_value_for, field, value)
          end
        end
      end

      context "and the field type is a hash" do

        before { field.stubs(:type => Hash) }

        it "should let the field typecast the value" do
          value = { "name" => "John" }
          field.expects(:serialize).with(value).once
          selector.send(:typecast_value_for, field, value)
        end
      end
    end
  end
end
