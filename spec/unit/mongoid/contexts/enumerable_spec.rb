require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before do
    @london = Address.new(:street => "Bond Street")
    @shanghai = Address.new(:street => "Nan Jing Dong Lu")
    @melbourne = Address.new(:street => "Bourke Street")
  end

  describe "#execute" do

    before do
      @docs = [ @london, @shanghai, @melbourne ]
      @selector = { :street => "Bond Street" }
      @context = Mongoid::Contexts::Enumerable.new(@selector, {}, @docs)
    end

    it "returns the matching documents from the array" do
      @context.execute.should == [ @london ]
    end

  end

  describe ".initialize" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }
    let(:documents) { [stub] }

    before do
      @context = Mongoid::Contexts::Enumerable.new(selector, options, documents)
    end

    it "sets the selector" do
      @context.selector.should == selector
    end

    it "sets the options" do
      @context.options.should == options
    end

    it "sets the documents" do
      @context.documents.should == documents
    end

  end

end
