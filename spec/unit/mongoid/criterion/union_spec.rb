require "spec_helper"

describe Mongoid::Criterion::Union do

  let(:context) do
    stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
  end

  let(:first) do
    criteria = Mongoid::Criteria.new(Person)
    criteria.where(:title => "Sir")
  end

  let(:second) do
    criteria = Mongoid::Criteria.new(Person)
    criteria.where(:title => "Mam")
  end

  let(:third) do
    criteria = Mongoid::Criteria.new(Person)
    criteria.where(:title => "Mr")
  end

  let(:fourth) do
    criteria = Mongoid::Criteria.new(Person)
    criteria.where(:title => "Mrs")
  end

  before do
    @sir = Person.new(:title => "Sir")
    @mam = Person.new(:title => "Mam")
    @mrs = Person.new(:title => "Mrs")
    @mr = Person.new(:title => "Mr")
  end

  describe "#identifiers" do

    before do
      Mongoid::Contexts::Mongo.expects(:new).returns(context)
      context.expects(:execute).returns([@sir])
    end

    it "returns the ids of the found documents" do
      first.identifiers.should == [ @sir.id ]
    end
  end

  describe "#or" do

    context "when unioning 2 criteria" do

      before do
        Mongoid::Contexts::Mongo.expects(:new).twice.returns(context)
        context.expects(:execute).twice.returns([@sir], [@mam])
      end

      it "unions the criteria" do
        first.or(second).should == [ @sir, @mam ]
      end
    end

    context "when unioning more than 2 criteria" do

      before do
        Mongoid::Contexts::Mongo.expects(:new).times(4).returns(context)
        context.expects(:execute).times(4).returns([@sir], [@mam], [@mrs], [@mr])
      end

      it "unions all the criteria" do
        first.or(second).or(third).or(fourth).should == [ @sir, @mam, @mrs, @mr ]
      end
    end

  end

  describe "#union" do

    before do
      Mongoid::Contexts::Mongo.expects(:new).twice.returns(context)
      context.expects(:execute).twice.returns([@sir], [@mam])
    end

    it "aliases to #or" do
      first.union(second).should == [ @sir, @mam ]
    end
  end
end
