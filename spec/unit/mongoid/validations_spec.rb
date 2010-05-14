require "spec_helper"

describe Mongoid::Validations do
  after(:all) do
    Person._types.each do |t|
      Object.send(:remove_const, t.to_s)
    end
    load 'models/person.rb'

    Canvas._types.each do |t|
      Object.send(:remove_const, t.to_s)
    end
    load 'models/inheritance.rb'
  end

  describe ".validates_associated" do

    before do
      @class = MixedDrink
    end

    it "adds the associated validator" do
      @class.expects(:validates_with).with(Mongoid::Validations::AssociatedValidator, { :attributes => [ :name ] })
      @class.validates_associated(:name)
    end

    it "is picked up by validates method" do
      @class.expects(:validates_with).with(Mongoid::Validations::AssociatedValidator, { :attributes => [ :name ] })
      @class.validates(:name, :associated => true)
    end

  end

  describe ".validates_uniqueness_of" do

    before do
      @class = MixedDrink
    end

    it "adds the uniqueness validator" do
      @class.expects(:validates_with).with(Mongoid::Validations::UniquenessValidator, { :attributes => [ :title ] })
      @class.validates_uniqueness_of(:title)
    end

    it "is picked up by validates method" do
      @class.expects(:validates_with).with(Mongoid::Validations::UniquenessValidator, { :attributes => [ :title ] })
      @class.validates(:title, :uniqueness => true)
    end

  end

  context "when running validations" do

    before do
      @person = Person.new
      @canvas = Canvas.new
      @firefox = Firefox.new
    end

    describe "#validates_acceptance_of" do

      it "fails if field not accepted" do
        Person.class_eval do
          validates_acceptance_of :terms, :allow_nil => false
        end
        @person.valid?.should be_false
        @person.errors[:terms].should_not be_nil
      end

    end

    describe "#validates_associated" do

      context "when association is a has_many" do

        it "fails when any association fails validation" do
          Person.class_eval do
            validates_associated :addresses
          end
          Address.class_eval do
            validates_presence_of :street
          end
          @person.addresses << Address.new
          @person.valid?.should be_false
          @person.errors[:addresses].should_not be_nil
        end

      end

      context "when association is a has_one" do

        context "when the associated is not nil" do

          it "fails when the association fails validation" do
            Person.class_eval do
              validates_associated :name
            end
            Name.class_eval do
              validates_presence_of :first_name
            end
            @person.name = Name.new
            @person.valid?.should be_false
            @person.errors[:name].should_not be_nil
          end

        end

        context "when the associated is nil" do

          it "returns true" do
            Person.class_eval do
              validates_associated :name
            end
            @person.valid?
            @person.errors[:name].should be_empty
          end

        end

      end

    end

    describe "#validates_format_of" do

      it "fails if the field is in the wrong format" do
        Person.class_eval do
          validates_format_of :title, :with => /[A-Za-z]/
        end
        @person.title = 10
        @person.valid?.should be_false
        @person.errors[:title].should_not be_nil
      end

    end

    describe "#validates_length_of" do

      it "fails if the field is the wrong length" do
        Person.class_eval do
          validates_length_of :title, :minimum => 10
        end
        @person.title = "Testing"
        @person.valid?.should be_false
        @person.errors[:title].should_not be_nil
      end

    end

    describe "#validates_numericality_of" do

      it "fails if the field is not a number" do
        Person.class_eval do
          validates_numericality_of :age
        end
        @person.age = "foo"
        @person.valid?.should be_false
        @person.errors[:age].should_not be_nil
      end

    end

    describe "#validates_presence_of" do

      context "on a parent class" do

        it "fails if the field is nil on the parent" do
          Person.class_eval do
            validates_presence_of :title
          end
          @person.valid?.should be_false
          @person.errors[:title].should_not be_nil
        end

        it "fails if the field is nil on a subclass" do
          Canvas.class_eval do
            validates_presence_of :name
          end
          @firefox.valid?.should be_false
          @firefox.errors[:name].should_not be_nil
        end

      end

      context "on a subclass" do

        it "parent class does not get subclass validations" do
          Firefox.class_eval do
            validates_presence_of :version
          end
          @canvas.name = "Testing"
          @canvas.valid?.should be_true
        end

      end

    end

  end

end
