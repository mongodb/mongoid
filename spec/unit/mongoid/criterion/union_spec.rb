require "spec_helper"

describe Mongoid::Criterion::Union do

  let(:context) do
    stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
  end

  let(:left) do
    criteria = Mongoid::Criteria.new(Person)
    criteria.where(:title => "Sir")
  end

  let(:right) do
    criteria = Mongoid::Criteria.new(Person)
    criteria.where(:title => "Mam")
  end

  before do
    @sir = Person.new(:title => "Sir")
    @mam = Person.new(:title => "Mam")
    Mongoid::Contexts::Mongo.expects(:new).twice.returns(context)
  end

  describe "#or" do

    before do
      context.expects(:execute).twice.returns([@sir], [@mam])
    end

    it "executes the criteria" do
      left.or(right).should == [ @sir, @mam ]
    end
  end

  describe "#union" do

    before do
      context.expects(:execute).twice.returns([@sir], [@mam])
    end

    it "aliases to #or" do
      left.union(right).should == [ @sir, @mam ]
    end
  end
end
