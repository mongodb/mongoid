require "spec_helper"

describe Mongoid::Relations::Embedded::Sort do
  include Mongoid::Relations::Embedded::Sort

  let(:pig)      { Animal.new(:height => 1, :weight => 120, :name => 'Pig') }
  let(:elephant) { Animal.new(:height => 4, :weight => 900, :name => 'Elephant') }
  let(:giraffe)  { Animal.new(:height => 6, :weight => 900, :name => 'Giraffe') }


  let(:order) { sort_documents!(documents, metadata) }
  let(:metadata) { stub(:klass => Animal, :order => criteria)}

  let(:documents) { [pig, elephant, giraffe] }

  describe "#sort_documents_by_criteria!" do
    context "with single sort criteria" do
      context "defined as Criterion::Complex" do
        let(:criteria) { :height.desc }

        it "order documents" do
          order
          documents.should == [giraffe, elephant, pig]
        end
      end

      context "defined as Array" do
        let(:criteria) { [:height, :desc] }

        it "order documents" do
          order
          documents.should == [giraffe, elephant, pig]
        end
      end

      context "defined as Hash" do
        let(:criteria) { {:height => :desc} }

        it "order documents" do
          order
          documents.should == [giraffe, elephant, pig]
        end
      end
    end

    context "with multiple sort criterias" do
      context "defined as Criterion::Complex" do
        let(:criteria) { [:weight.desc, :height.asc] }

        it "order documents" do
          order
          documents.should == [elephant, giraffe, pig]
        end
      end

      context "defined as Array" do
        let(:criteria) { [[:weight, :desc], [:height, :asc]] }

        it "order documents" do
          order
          documents.should == [elephant, giraffe, pig]
        end
      end

      context "defined as array of hashs" do
        let(:criteria) { [{:weight => :desc}, {:height => :asc}]  }

        it "order documents" do
          order
          documents.should == [elephant, giraffe, pig]
        end
      end

      context "defined as mix" do
        let(:criteria) { [:weight.desc, {:height => :asc}]  }

        it "order documents" do
          order
          documents.should == [elephant, giraffe, pig]
        end
      end

    end

  end

end
