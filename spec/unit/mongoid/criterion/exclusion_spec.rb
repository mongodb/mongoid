require "spec_helper"

describe Mongoid::Criterion::Exclusion do

  let(:base) do
    Mongoid::Criteria.new(Person)
  end

  describe "#excludes" do

    let(:criteria) do
      base.excludes(:title => "Bad Title", :text => "Bad Text")
    end

    it "adds the $ne query to the selector" do
      criteria.selector.should ==
        {
          :title =>
            { "$ne" => "Bad Title"},
          :text =>
            { "$ne" => "Bad Text" }
        }
    end

    it "returns a copy" do
      base.excludes(:title => "Bad").should_not eql(base)
    end

    context "when passing an id" do

      context "when setting the field as id" do

        let(:criteria) do
          base.excludes(:id => "1")
        end

        it "updates the selector" do
          criteria.selector.should ==
            {
              :_id => { "$ne" => "1" }
            }
        end
      end

      context "when setting the field as _id" do

        let(:criteria) do
          base.excludes(:_id => "1")
        end

        it "updates the selector" do
          criteria.selector.should ==
            {
              :_id => { "$ne" => "1" }
            }
        end
      end
    end

    context "when existing ne criteria exists" do

      let(:criteria) do
        base.
          excludes(:title => "Bad Title").
          excludes(:text => "Bad Text")
      end

      it "appends to the selector" do
        criteria.selector.should ==
          {
            :title =>
              { "$ne" => "Bad Title"},
            :text =>
              { "$ne" => "Bad Text" }
          }
      end
    end
  end

  describe "#fields" do

    let(:criteria) do
      base.fields(:field => 1)
    end

    let(:options) do
      criteria.options[:fields]
    end

    it "adds the exclusion to the options" do
      options.should == { :field => 1 }
    end

    it "returns a copy" do
      base.fields(:field => 1).should_not eql(base)
    end
  end

  describe "#not_in" do

    let(:criteria) do
      base.not_in(:title => ["title1", "title2"], :text => ["test"])
    end

    it "adds the exclusion to the selector" do
      criteria.selector.should == {
        :title => { "$nin" => ["title1", "title2"] },
        :text => { "$nin" => ["test"] }
      }
    end

    it "returns a copy" do
      base.not_in(:title => ["title1"]).should_not eql(base)
    end

    context "when existing nin criteria exists" do

      let(:criteria) do
        base.
          not_in(:title => ["title1", "title2"]).
          not_in(:title => ["title3"], :text => ["test"])
      end

      it "appends to the nin selector" do
        criteria.selector.should == {
          :title => { "$nin" => ["title1", "title2", "title3"] },
          :text => { "$nin" => ["test"] }
        }
      end
    end
  end

  describe "#only" do

    context "when args are provided" do

      before do
        Person.create(:age => 50)
      end

      let(:criteria) do
        base.only(:title, :text)
      end

      it "adds the options for limiting by fields" do
        criteria.options.should eq(
          { :fields => { :_type => 1, :title => 1, :text => 1 }}
        )
      end

      it "returns a copy" do
        base.only.should_not eql(base)
      end

      it "assigns the field list" do
        criteria.without(:title, :text).field_list.should eq([ :title, :text ])
      end

      it "does not apply defaults" do
        criteria.first.age.should be_nil
      end
    end

    context "when no args provided" do

      let(:criteria) do
        base.only
      end

      it "does not add the field option" do
        criteria.options[:fields].should be_nil
      end

      it "should not assign the field list" do
        criteria.only.field_list.should be_nil
      end
    end
  end

  describe "#without" do

    let!(:person) do
      Person.create(:ssn => "123-11-1233")
    end

    context "when used in a named scope" do

      let(:documents) do
        Person.without_ssn
      end

      it "limits the document fields" do
        documents.first.ssn.should be_nil
      end
    end

    context "when args are provided" do

      let(:criteria) do
        base.without(:title, :text, :age)
      end

      it "adds the options for excluding the fields" do
        criteria.options.should eq({ :fields => { :title => 0, :text => 0, :age => 0 } })
      end

      it "returns self" do
        criteria.without.should == criteria
      end

      it "does not apply defaults" do
        criteria.first.age.should be_nil
      end
    end

    context "when no args provided" do

      let(:criteria) do
        base.without
      end

      it "does not add the field option" do
        criteria.options[:fields].should be_nil
      end

      it "should not assign the field list" do
        criteria.field_list.should be_nil
      end
    end
  end
end
