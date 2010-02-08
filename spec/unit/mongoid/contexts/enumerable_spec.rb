require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before do
    @london = Address.new(:number => 1, :street => "Bond Street")
    @shanghai = Address.new(:number => 10, :street => "Nan Jing Dong Lu")
    @melbourne = Address.new(:number => 20, :street => "Bourke Street")
    @new_york = Address.new(:number => 20, :street => "Broadway")
    @docs = [ @london, @shanghai, @melbourne, @new_york ]
    @selector = { :street => "Bourke Street" }
    @options = { :fields => [ :number ] }
    @context = Mongoid::Contexts::Enumerable.new(@selector, @options, @docs)
  end

  describe "#aggregate" do

    before do
      @counts = @context.aggregate
    end

    it "groups by the fields provided in the options" do
      @counts.size.should == 3
    end

    it "stores the counts in proper groups" do
      @counts[1].should == 1
      @counts[10].should == 1
      @counts[20].should == 2
    end
  end

  describe "#count" do

    it "returns the size of the enumerable" do
      @context.count.should == 4
    end

  end

  describe "#execute" do

    it "returns the matching documents from the array" do
      @context.execute.should == [ @melbourne ]
    end

    context "when selector is empty" do

      before do
        @context = Mongoid::Contexts::Enumerable.new({}, @options, @docs)
      end

      it "returns all the documents" do
        @context.execute.should == @docs
      end
    end

    context "when skip and limit are in the options" do

      before do
        @options = { :skip => 2, :limit => 2 }
        @context = Mongoid::Contexts::Enumerable.new({}, @options, @docs)
      end

      it "properly narrows down the matching results" do
        @context.execute.should == [ @melbourne, @new_york ]
      end
    end

  end

  describe "#first" do

    context "when a selector is present" do

      it "returns the first that matches the selector" do
        @context.first.should == @melbourne
      end
    end

  end

  describe "#group" do

    before do
      @group = @context.group
    end

    it "groups by the fields provided in the options" do
      @group.size.should == 3
    end

    it "stores the documents in proper groups" do
      @group[1].should == [ @london ]
      @group[10].should == [ @shanghai ]
      @group[20].should == [ @melbourne, @new_york ]
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

  describe "#last" do

    it "returns the last matching in the enumerable" do
      @context.last.should == @melbourne
    end

  end

  describe "#max" do

    it "returns the max value for the supplied field" do
      @context.max(:number).should == 20
    end

  end

  describe "#min" do

    it "returns the min value for the supplied field" do
      @context.min(:number).should == 1
    end

  end

  describe "#one" do

    it "returns the first matching in the enumerable" do
      @context.one.should == @melbourne
    end

  end

  describe "#page" do

    context "when the page option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :page => 5 })
        @context = Mongoid::Contexts::Enumerable.new({}, @criteria.options, [])
      end

      it "returns the page option" do
        @context.page.should == 5
      end

    end

    context "when the page option does not exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @context = Mongoid::Contexts::Enumerable.new({}, @criteria.options, [])
      end

      it "returns 1" do
        @context.page.should == 1
      end

    end

  end

  describe "#paginate" do

    before do
      @criteria = Person.criteria.skip(2).limit(2)
      @context = Mongoid::Contexts::Enumerable.new({}, @criteria.options, @docs)
      @results = @context.paginate
    end

    it "executes and paginates the results" do
      @results.current_page.should == 2
      @results.per_page.should == 2
    end

  end

  describe "#per_page" do

    context "when a limit option exists" do

      it "returns 20" do
        @context.per_page.should == 20
      end

    end

    context "when a limit option does not exist" do

      before do
        @context = Mongoid::Contexts::Enumerable.new({}, { :limit => 50 }, [])
      end

      it "returns the limit" do
        @context.per_page.should == 50
      end

    end

  end

  describe "#sum" do

    it "returns the sum of all the field values" do
      @context.sum(:number).should == 51
    end

  end

end
