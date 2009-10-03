require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

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

    it "adds all the documents public methods to the class" do
      @decorated.decorate!
      @decorated.should respond_to(:title, :terms, :age, :addresses, :name)
    end

  end

end
