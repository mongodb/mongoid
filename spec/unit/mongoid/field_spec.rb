require "spec_helper"

describe Mongoid::Field do

  describe "#default" do

    before do
      @field = Mongoid::Field.new(:score, :type => Integer, :default => 0)
    end

    it "returns the default option" do
      @field.default.should == 0
    end

    it "returns the typed value" do
      @field.expects(:set).with(0)
      @field.default
    end

    context "when the field is an array" do

      context "when the array is user defined" do

        before do
          @field = Mongoid::Field.new(
            :vals,
            :type => Array,
            :default => [ "first" ]
          )
        end

        it "dups the array" do
          array = @field.default
          array << "second"
          @field.default.should == [ "first" ]
        end
      end

      context "when the array is object ids" do

        let(:field) do
          Mongoid::Field.new(
            :vals,
            :type => Array,
            :default => [],
            :identity => true,
            :inverse_class_name => "Game"
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
            Game.identity :type => String
          end

          after do
            Game.identity :type => BSON::ObjectId
          end

          it "does not convert" do
            field.set([object_id.to_s]).should == [object_id.to_s]
          end
        end
      end
    end

    context "when the field is a hash" do

      before do
        @field = Mongoid::Field.new(
          :vals,
          :type => Hash,
          :default => { :key => "value" }
        )
      end

      it "dups the hash" do
        hash = @field.default
        hash[:key_two] = "value2"
        @field.default.should == { :key => "value" }
      end
    end
  end

  describe "#initialize" do

    context "when the field name is invalid" do

      it "raises an error" do
        lambda {
          Mongoid::Field.new(:collection, Person)
        }.should raise_error(Mongoid::Errors::InvalidField)
      end
    end

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

    before do
      @field = Mongoid::Field.new(
        :score,
        :type => Integer,
        :default => 0
      )
    end

    it "returns the name" do
      @field.name.should == :score
    end
  end

  describe "#type" do

    before do
      @field = Mongoid::Field.new(:name)
    end

    it "defaults to Object" do
      @field.type.should == Object
    end
  end

  describe "#set" do

    before do
      @field = Mongoid::Field.new(
        :score,
        :default => 10,
        :type => Integer
      )
    end

    context "nil is provided" do

      it "returns the default value" do
        @field.set(nil).should == nil
      end

    end

    context "value is provided" do

      it "sets the value" do
        @field.set("30").should == 30
      end
    end
  end

  describe "#get" do

    before do
      @field = Mongoid::Field.new(
        :score,
        :default => 10,
        :type => Integer
      )
    end

    it "returns the value" do
      @field.get(30).should == 30
    end
  end

  describe "#options" do
    before do
      @field = Mongoid::Field.new(
        :terrible_and_unsafe_html_goes_here,
        :sanitize => true,
        :hello => :goodbye
      )
    end

    it "stores the arbitrary options" do
      @field.options[:sanitize].should be_true
      @field.options[:hello].should == :goodbye
    end
  end
end
