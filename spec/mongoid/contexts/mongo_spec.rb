require "spec_helper"

describe Mongoid::Contexts::Mongo do

  describe "#avg" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.avg(:age).should be_nil
      end
    end

    context "when documents exist in the collection" do

      context "when values exist for the field" do

        before do
          5.times do |n|
            Person.create(
              :title => "Sir",
              :age => ((n + 1) * 10),
              :aliases => ["D", "Durran"]
            )
          end
        end

        it "returns the average for the field" do
          Person.avg(:age).should eq(30)
        end
      end

      context "when values do not exist" do

        before do
          Person.create
        end

        it "returns nil" do
          Person.avg(:score).should eq(0)
        end
      end

      context "when no document has the field" do

        before do
          Person.create
        end

        it "returns 0" do
          Person.avg(:no_definition).should eq(0)
        end
      end
    end
  end

  describe "#count" do

    context "when documents exist in the collection" do

      before do
        13.times do |n|
          Person.create(
            :title => "Sir",
            :age => ((n + 1) * 10),
            :aliases => ["D", "Durran"]
          )
        end
      end

      context "without skip or limit" do

        it "returns the number of documents" do
          Person.count.should eq(13)
        end
      end

      context "with skip and limit" do

        context "by default" do

          it "ignores previous offset/limit statements" do
            Person.limit(5).offset(10).count.should eq(13)
          end
        end

        context "when passed 'true'" do

          it "includes previous offset/limit statements" do
            Person.limit(5).offset(5).count(true).should eq(5)
          end
        end

        context "when passed 'false'" do

          it "ignores previous offset/limit statements" do
            Person.limit(5).offset(10).count(false).should eq(13)
          end
        end
      end
    end
  end

  describe "#empty?" do

    context "when no documents are in the collection" do

      it "returns true" do
        Person.empty?.should be_true
      end
    end

    context "when some documents are in the collection" do

      before do
        2.times do |n|
          Person.create(
            :title => "Sir",
            :age => ((n + 1) * 10),
            :aliases => ["D", "Durran"]
          )
        end
      end

      it "returns false" do
        Person.empty?.should be_false
      end
    end
  end

  describe "#first" do

    let!(:first) do
      Product.create
    end

    let!(:last) do
      Product.create
    end

    let(:from_db) do
      Product.first
    end

    it "returns the first document in the collection by id" do
      from_db.should eq(first)
    end

    context "when chained on another criteria" do

      let(:criteria) do
        Product.desc(:description)
      end

      before do
        criteria.first
      end

      it "does not modify the previous criteria's sorting" do
        criteria.options.should eq({ :sort => [[ :"description.en", :desc ]] })
      end
    end
  end

  describe "#last" do

    let!(:first) do
      Product.create
    end

    let!(:last) do
      Product.create
    end

    let(:from_db) do
      Product.last
    end

    it "returns the last document in the collection by id" do
      from_db.should eq(last)
    end

    context "when chained on another criteria" do

      let(:criteria) do
        Product.desc(:description)
      end

      before do
        criteria.last
      end

      it "does not modify the previous criteria's sorting" do
        criteria.options.should eq({ :sort => [[ :"description.en", :desc ]] })
      end
    end
  end

  describe "#max" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.max(:age).should be_nil
      end
    end

    context "when documents are in the collection" do

      before do
        5.times do |n|
          Person.create(
            :title => "Sir",
            :age => (n * 10),
            :aliases => ["D", "Durran"]
          )
        end
      end

      it "returns the maximum for the field" do
        Person.max(:age).should eq(40)
      end

      context "when the field is not defined" do

        before do
          Person.create
          Person.create(:no_definition => 5)
        end

        it "returns the sum" do
          Person.max(:no_definition).should eq(5)
        end
      end

      context "when no document has the field" do

        before do
          Person.create
        end

        it "returns 0" do
          Person.max(:no_definition).should eq(0)
        end
      end
    end
  end

  describe "#min" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.min(:age).should be_nil
      end
    end

    context "when documents are in the collection" do

      before do
        5.times do |n|
          Person.create(
            :title => "Sir",
            :age => ((n + 1) * 10),
            :aliases => ["D", "Durran"]
          )
        end
      end

      it "returns the minimum for the field" do
        Person.min(:age).should eq(10.0)
      end

      context "when the field is not defined" do

        before do
          Person.create
          Person.create(:no_definition => 5)
        end

        it "returns the sum" do
          Person.min(:no_definition).should eq(5)
        end
      end

      context "when no document has the field" do

        before do
          Person.create
        end

        it "returns 0" do
          Person.min(:no_definition).should eq(0)
        end
      end
    end

    context "when the returned value is not a number" do

      let(:time) do
        Time.now.utc
      end

      before do
        Person.create(:lunch_time => time)
      end

      it "returns the value" do
        Person.min(:lunch_time).should be_within(1).of(time)
      end
    end
  end

  describe "#sum" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.sum(:age).should be_nil
      end
    end

    context "when documents are in the collection" do

      context "when they contain the field" do

        before do
          2.times do |n|
            Person.create(
              :title => "Sir",
              :age => 5,
              :aliases => ["D", "Durran"]
            )
          end
        end

        it "returns the sum for the field" do
          Person.where(:age.gt => 3).sum(:age).should eq(10)
        end
      end

      context "when they do not contain the field" do

        before do
          Person.create
        end

        it "returns nil" do
          Person.sum(:score).should eq(0)
        end
      end

      context "when the field is not defined" do

        before do
          Person.create
          Person.create(:no_definition => 5)
        end

        it "returns the sum" do
          Person.sum(:no_definition).should eq(5)
        end
      end

      context "when no document has the field" do

        before do
          Person.create
        end

        it "returns 0" do
          Person.sum(:no_definition).should eq(0)
        end
      end
    end
  end
end
