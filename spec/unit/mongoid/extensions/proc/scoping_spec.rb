require "spec_helper"

describe Mongoid::Extensions::Proc::Scoping do

  describe "#scoped" do

    context "when the proc accessed a hash" do

      before do
        @proc = lambda { |number| { :where => { :count => number } } }
      end

      it "calls the hash with the args" do
        @proc.scoped(10).should == { :where => { :count => 10 } }
      end

    end

    context "when the proc calls a criteria" do

      before do
        @proc = lambda { |title| Person.where(:title => title) }
      end

      it "returns the criteria scoped" do
        @proc.scoped("Sir").should ==
          { :where => { :_type => { "$in" => [ "Doctor", "Person" ] }, :title => "Sir" } }
      end

    end

  end

end
