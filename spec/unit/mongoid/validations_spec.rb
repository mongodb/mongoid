require "spec_helper"

describe Mongoid::Validations do

  before(:all) do
    Person.logger = nil
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
end
