require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

class Person < Mongoid::Document
  field :title
  field :terms, :type => Boolean
  field :age, :type => Integer, :default => 100
  field :dob, :type => Date
  has_many :addresses
  has_one :name
end

class Address < Mongoid::Document
  field :street
  key :street
  belongs_to :person
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

class Decorated
  include Mongoid::Associations::Decorator
  def initialize(doc)
    @document = doc
  end
end

describe Mongoid::Associations::Decorator do

  describe "#included" do

    before do
      @person = Person.new
      @decorated = Decorated.new(@person)
    end

    it "adds a document reader" do
      @decorated.should respond_to(:document)
    end

    it "adds a decorate! instance method" do
      @decorated.should respond_to(:decorate!)
    end

  end

  describe "#decorate!" do

    before do
      @person = Person.new
      @decorated = Decorated.new(@person)
    end

    it "adds all the documents methods to the class" do
      @decorated.decorate!
      @decorated.should respond_to(:title, :terms, :age, :addresses, :name, :save)
    end

  end

end
