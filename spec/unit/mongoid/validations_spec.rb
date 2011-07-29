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
end
