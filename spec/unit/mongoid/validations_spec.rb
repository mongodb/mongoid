require "spec_helper"

describe Mongoid::Validations do

  let(:klass) { MixedDrink }

  describe "#read_attribute_for_validation" do

    let(:person) do
      Person.new(:title => "Mr")
    end

    let!(:address) do
      person.addresses.build(:street => "Wienerstr")
    end

    context "when reading a field" do

      let(:value) do
        person.read_attribute_for_validation(:title)
      end

      it "returns the value" do
        value.should == "Mr"
      end
    end

    context "when reading a relation" do

      let(:value) do
        person.read_attribute_for_validation(:addresses)
      end

      let(:documents) do
        Mongoid::Relations::Targets::Enumerable.new([ address ])
      end

      before do
        person.instance_variable_set(:@addresses, documents)
      end

      it "returns the value" do
        value.should == [ address ]
      end
    end
  end

  describe ".validates_associated" do

    before do
      klass.expects(:validates_with).with(
        Mongoid::Validations::AssociatedValidator, { :attributes => [ :name ] }
      )
    end

    it "adds the associated validator" do
      klass.validates_associated(:name)
    end

    it "is picked up by validates method" do
      klass.validates(:name, :associated => true)
    end

  end

  describe ".validates_uniqueness_of" do

    before do
      klass.expects(:validates_with).with(
        Mongoid::Validations::UniquenessValidator, { :attributes => [ :title ] }
      )
    end

    it "adds the uniqueness validator" do
      klass.validates_uniqueness_of(:title)
    end

    it "is picked up by validates method" do
      klass.validates(:title, :uniqueness => true)
    end
  end

  describe ".validates_presence_of" do
    before do
      klass.expects(:validates_with).with(
        Mongoid::Validations::PresenceValidator, { :attributes => [ :title ] }
      )
    end

    it "adds the presence validator" do
      klass.validates_presence_of(:title)
    end

    it "is picked up by validates method" do
      klass.validates(:title, :presence => true)
    end
  end

  describe ".validates_format_of" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
      end
    end

    context "when adding via the traditional macro" do

      before do
        klass.validates_format_of(:website, :with => URI.regexp)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::FormatValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:website, :format => { :with => URI.regexp })
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::FormatValidator
        )
      end
    end
  end
end
