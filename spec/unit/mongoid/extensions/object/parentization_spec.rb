require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

class Person < Mongoid::Document
  field :title
  has_one :name
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

describe Mongoid::Extensions::Object::Parentization do

  describe "#parentize" do

    before do
      @parent = Person.new
      @child = Name.new
    end

    it "sets the parent on each element" do
      @child.parentize(@parent, :child)
      @child.parent.should == @parent
    end

  end

end
