require "spec_helper"

describe Mongoid::Matchers do

  describe "#matches?" do

    context "when performing simple matching" do

      before do
        @document = Address.new(:street => "Clarkenwell Road")
      end

      context "when the attributes match" do

        before do
          @selector = { :street => "Clarkenwell Road" }
        end

        it "returns true" do
          @document.matches?(@selector).should be_true
        end

      end

      context "when the attributes dont match" do

        before do
          @selector = { :street => "Broadway Ave" }
        end

        it "returns false" do
          @document.matches?(@selector).should be_false
        end

      end

    end

    context "when performing complex matching" do

      before do
        @document = Address.new(:services => ["first", "second"], :number => 100)
      end

      context "with an $all selector" do

        context "when the attributes match" do

          before do
            @selector = { :services => { "$all" => [ "first", "second" ] } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :services => { "$all" => [ "first" ] } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with an $exists selector" do

        context "when the attributes match" do

          before do
            @selector = { :services => { "$exists" => true } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :services => { "$exists" => false } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with a $gt selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$gt" => 50 } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$gt" => 200 } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with a $gte selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$gte" => 100 } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$gte" => 200 } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with an $in selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$in" => [ 100, 200 ] } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$in" => [ 200, 300 ] } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with a $lt selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$lt" => 200 } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$lt" => 50 } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with a $lte selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$lte" => 200 } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$lte" => 50 } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with an $ne selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$ne" => 200 } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$ne" => 100 } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with a $nin selector" do

        context "when the attributes match" do

          before do
            @selector = { :number => { "$nin" => [ 1, 2, 3 ] } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :number => { "$nin" => [ 100 ] } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

      context "with a $size selector" do

        context "when the attributes match" do

          before do
            @selector = { :services => { "$size" => 2 } }
          end

          it "returns true" do
            @document.matches?(@selector).should be_true
          end

        end

        context "when the attributes do not match" do

          before do
            @selector = { :services => { "$size" => 5 } }
          end

          it "returns false" do
            @document.matches?(@selector).should be_false
          end

        end

      end

    end

  end

end
