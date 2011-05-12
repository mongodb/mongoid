require "spec_helper"

describe Mongoid::Field do

  describe ".options" do

    it "returns a hash of custom options" do
      Mongoid::Field.options.should be_a Hash
    end

    it "is memoized" do
      Mongoid::Field.options.should equal Mongoid::Field.options
    end
  end

  describe ".option" do

    let(:options) { Mongoid::Field.options }

    let(:handler) do
      proc {}
    end

    it "stores the custom option in the options hash" do
      options.expects(:[]=).with(:option, handler)
      Mongoid::Field.option(:option, &handler)
    end
  end

  describe "#cast_on_read?" do

    [ Date, DateTime, Time, BigDecimal, Image ].each do |klass|

      context "when the type is a #{klass}" do

        let(:field) do
          Mongoid::Field.new(:field_name, :type => klass)
        end

        it "returns true" do
          field.should be_cast_on_read
        end
      end
    end

    [
      Array, Binary, Boolean, Float, Hash,
      Integer, BSON::ObjectId, Set, String, Symbol
    ].each do |klass|

      context "when the type is a #{klass}" do

        let(:field) do
          Mongoid::Field.new(:field_name, :type => klass)
        end

        it "returns false" do
          field.should_not be_cast_on_read
        end
      end
    end
  end

  describe "#default" do

    let(:field) do
      Mongoid::Field.new(:score, :type => Integer, :default => 0)
    end

    it "returns the default option" do
      field.default.should == 0
    end

    it "returns the typed value" do
      field.expects(:set).with(0)
      field.default
    end

    context "when the field is an array" do

      context "when the array is user defined" do

        let(:field) do
          Mongoid::Field.new(
            :vals,
            :type => Array,
            :default => [ "first" ]
          )
        end

        let(:array) do
          field.default
        end

        before do
          array << "second"
        end

        it "dups the array" do
          field.default.should == [ "first" ]
        end
      end

      context "when the array is object ids" do

        let(:metadata) do
          Mongoid::Relations::Metadata.new(
            :inverse_class_name => "Game",
            :name => :person,
            :relation => Mongoid::Relations::Referenced::In
          )
        end

        let(:field) do
          Mongoid::Field.new(
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
            field.set([object_id.to_s]).should == [object_id]
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
            field.set([object_id.to_s]).should == [object_id.to_s]
          end
        end
      end
    end

    context "when the field is a hash" do

      let(:field) do
        Mongoid::Field.new(
          :vals,
          :type => Hash,
          :default => { :key => "value" }
        )
      end

      let(:hash) do
        field.default
      end

      before do
        hash[:key_two] = "value2"
      end

      it "dups the hash" do
        field.default.should == { :key => "value" }
      end
    end
  end

  describe "#initialize" do

    context "when the default value does not match the type" do

      it "raises an error" do
        lambda {
          Mongoid::Field.new(
            :names,
            :type => Integer,
            :default => "Jacob"
          )
        }.should raise_error(Mongoid::Errors::InvalidType)
      end
    end
  end

  describe "#name" do

    let(:field) do
      Mongoid::Field.new(
        :score,
        :type => Integer,
        :default => 0
      )
    end

    it "returns the name" do
      field.name.should == :score
    end
  end

  describe "#type" do

    let(:field) do
      Mongoid::Field.new(:name)
    end

    it "defaults to Object" do
      field.type.should == Object
    end
  end

  describe "#label" do

    it "defaults to nil" do
      Mongoid::Field.new(:name).label.should be_nil
    end

    it "allows a label to be set an retrieved" do
      Mongoid::Field.new(:name, :label => "Name").label.should == "Name"
    end
  end

  describe "#set" do

    let(:field) do
      Mongoid::Field.new(
        :score,
        :default => 10,
        :type => Integer
      )
    end

    context "nil is provided" do

      it "returns the default value" do
        field.set(nil).should == nil
      end
    end

    context "value is provided" do

      it "sets the value" do
        field.set("30").should == 30
      end
    end
  end

  describe "#get" do

    let(:field) do
      Mongoid::Field.new(
        :score,
        :default => 10,
        :type => Integer
      )
    end

    it "returns the value" do
      field.get(30).should == 30
    end
  end

  describe "#options" do

    let(:field) do
      Mongoid::Field.new(
        :terrible_and_unsafe_html_goes_here,
        :sanitize => true,
        :hello => :goodbye
      )
    end

    it "stores the arbitrary options" do
      field.options[:sanitize].should be_true
      field.options[:hello].should == :goodbye
    end
  end
end
