require "spec_helper"

describe Mongoid::Contexts::Enumerable::Sort do
  Sort = Mongoid::Contexts::Enumerable::Sort

  describe "#initialize" do
    let(:sort) { Sort.new("value", :asc) }

    it "sets the value" do
      sort.value.should == "value"
    end

    it "sets the sort order" do
      sort.direction.should == :asc
    end
  end

  describe "#ascending?" do
    subject { Sort.new("", direction).ascending? }

    context "when direction is :asc" do
      let(:direction) { :asc }
      it { should be_true }
    end

    context "when direction is :desc" do
      let(:direction) { :desc }
      it { should be_false }
    end
  end

  describe "#compare" do
    subject do
      Sort.allocate.send(:compare, value, other_value)
    end

    context "when a is nil" do
      let(:value) { nil }

      context "and b is nil" do
        let(:other_value) { nil }
        it { should == 0 }
      end

      context "and b is not nil" do
        let(:other_value) { "a" }
        it { should == 1 }
      end
    end

    context "when a is not nil" do
      let(:value) { "a" }

      context "and b is nil" do
        let(:other_value) { nil }
        it { should == -1 }
      end

      context "and b is not nil" do
        let(:other_value) { "b" }
        it "should use default comparison" do
          value.expects(:<=>).with(other_value)
          subject
        end
      end
    end
  end

  describe "<=>" do

    context "when direction is ascending" do
      it "returns the results of compare" do
        sort = Sort.new(0, :asc)
        other = stub(:value => 1)
        sort.expects(:compare).with(0, other.value).returns(-1)
        (sort <=> other).should == -1
      end
    end

    context "when direction is descending" do
      it "returns the inverse of compare" do
        sort = Sort.new(0, :desc)
        other = stub(:value => 1)
        sort.expects(:compare).with(0, other.value).returns(-1)
        (sort <=> other).should == 1
      end
    end

  end
end
