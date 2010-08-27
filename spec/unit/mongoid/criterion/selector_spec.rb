require "spec_helper"
require 'mongoid/criterion/selector'

describe Mongoid::Criterion::Selector do

  let(:field) { stub(:type => Integer) }

  describe "#initialize" do
    it "should store the class" do
      klass = stub
      Mongoid::Criterion::Selector.new(klass).klass.should == klass
    end
  end

  describe "[]=" do
    let(:klass) { Class.new }
    let(:selector) { Mongoid::Criterion::Selector.new(klass) }

    it "should store the values provided" do
      klass.stubs(:fields).returns({})
      selector["age"] = 45
      selector["age"].should == 45
    end

    it "should typecast values when possible" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:set).with("45").returns(45)
      selector["age"] = "45"
      selector["age"].should == 45
    end

    it "should typecast complex conditions" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:set).with("45").returns(45)
      selector["age"] = { "$gt" => "45" }
      selector["age"].should == { "$gt" => 45 }
    end
  end

  describe "update" do
    let(:klass) { Class.new }
    let(:selector) { Mongoid::Criterion::Selector.new(klass) }

    it "should typecast values when possible" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:set).with("45").returns(45)
      selector.update({"age" => "45"})
      selector["age"].should == 45
    end
  end

  describe "merge!" do
    let(:klass) { Class.new }
    let(:selector) { Mongoid::Criterion::Selector.new(klass) }

    it "should typecast values when possible" do
      klass.stubs(:fields).returns({"age" => field})
      field.expects(:set).with("45").returns(45)
      selector.merge!({"age" => "45"})
      selector["age"].should == 45
    end
  end

  describe "#try_to_typecast" do

    let(:klass) { Class.new }
    let(:selector) { Mongoid::Criterion::Selector.new(klass) }

    context "when the key is not a declared field" do
      it "returns the value" do
        klass.stubs(:fields).returns({})
        selector.send(:try_to_typecast, "age", "45").should == "45"
      end
    end

    context "when the key is a declared field" do
      it "returns the typecast value" do
        field = stub
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
        field.expects(:set).with("45")
        selector.send(:typecast_value_for, field, "45")
      end

      context "when the field is an array" do

        let(:field) { stub(:type => Array) }

        it "allows the simple value to be set" do
          String.expects(:set).with("007")
          selector.send(:typecast_value_for, field, "007")
        end
      end
    end

    context "when the value is a regex" do
      it "should return the regex unmodified" do
        field.expects(:set).never
        selector.send(:typecast_value_for, field, /Regex/)
      end
    end

    context "when the value is an array" do

      context "and the field type is array" do
        it "should let the field typecast the value" do
          field.stubs(:type).returns(Array)
          field.expects(:set).with([]).once
          selector.send(:typecast_value_for, field, [])
        end
      end

      context "and the field type is not array" do
        it "should typecast each value" do
          field.stubs(:type).returns(Integer)
          field.expects(:set).twice
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
            field.expects(:set).never
            selector.send(:typecast_value_for, field, value)
          end

          it "typecasts the value" do
            value = {"$exists" => "true"}
            Boolean.expects(:set).with("true")
            selector.send(:typecast_value_for, field, value)
          end

        end

        context "when the hash is a $size query" do

          it "should not typecast the hash" do
            value = {"$size" => 2}
            field.expects(:set).never
            selector.send(:typecast_value_for, field, value)
          end

          it "typecasts the value" do
            value = {"$size" => "2"}
            Integer.expects(:set).with("2")
            selector.send(:typecast_value_for, field, value)
          end

        end

      end

      context "and the field type is a hash" do
        before { field.stubs(:type => Hash) }

        it "should let the field typecast the value" do
          value = { "name" => "John" }
          field.expects(:set).with(value).once
          selector.send(:typecast_value_for, field, value)
        end

      end

    end
  end
end
