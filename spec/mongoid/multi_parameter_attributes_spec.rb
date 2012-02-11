require "spec_helper"

describe Mongoid::MultiParameterAttributes do

  describe "#process" do

    class Multi
      include Mongoid::Document
      include Mongoid::MultiParameterAttributes
      field :created_at, :type => Time
      field :dob, :type => Date
    end

    context "creating a multi" do

      let(:multi) do
        Multi.new(
          "created_at(1i)" => "2010",
          "created_at(2i)" => "8",
          "created_at(3i)" => "12",
          "created_at(4i)" => "15",
          "created_at(5i)" => "45"
        )
      end

      it "sets a multi-parameter Time attribute correctly" do
        multi.created_at.should eq(Time.local(2010, 8, 12, 15, 45))
      end

      it "does not leave ugly attributes on the model" do
        multi.attributes.should_not have_key("created_at(1i)")
      end
    end

    context "creating a multi" do

      context "with a valid DOB" do

        let(:multi) do
          Multi.new({
            "dob(1i)" => "1980",
            "dob(2i)" => "7",
            "dob(3i)" => "27"
          })
        end

        it "sets a multi-parameter Date attribute correctly" do
          multi.dob.should eq(Date.civil(1980, 7, 27))
        end
      end

      context "with an invalid DOB" do

        it "raises an exception" do
          lambda {
            Multi.new({
              "dob(1i)" => "1980",
              "dob(2i)" => "2",
              "dob(3i)" => "31"
            })
          }.should raise_exception(
            Mongoid::MultiParameterAttributes::Errors::MultiparameterAssignmentErrors,
            "1 error(s) on assignment of multiparameter attributes"
          )
        end
      end
    end

    context "with a blank DOB" do

      let(:multi) do
        Multi.new(
          "dob(1i)" => "",
          "dob(2i)" => "",
          "dob(3i)" => ""
        )
      end

      it "generates a nil date" do
        multi.dob.should be_nil
      end
    end

    context "with a partially blank DOB" do

      let(:multi) do
        Multi.new(
          "dob(1i)" => "1980",
          "dob(2i)" => "",
          "dob(3i)" => ""
        )
      end

      it "sets empty date's year" do
        multi.dob.year.should eq(1980)
      end

      it "sets empty date's month" do
        multi.dob.month.should eq(1)
      end

      it "sets empty date's day" do
        multi.dob.day.should eq(1)
      end
    end
  end
end
