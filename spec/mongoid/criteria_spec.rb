require "spec_helper"

describe Mongoid::Criteria do

  describe "#==" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when the other is a criteria" do

      context "when the criteria are the same" do

        let(:other) do
          Band.where(name: "Depeche Mode")
        end

        it "returns true" do
          criteria.should eq(other)
        end
      end

      context "when the criteria differ" do

        let(:other) do
          Band.where(name: "Tool")
        end

        it "returns false" do
          criteria.should_not eq(other)
        end
      end
    end

    context "when the other is an enumerable" do

      context "when the entries are the same" do

        let!(:band) do
          Band.create(name: "Depeche Mode")
        end

        let(:other) do
          [ band ]
        end

        it "returns true" do
          criteria.should eq(other)
        end
      end

      context "when the entries are not the same" do

        let!(:band) do
          Band.create(name: "Depeche Mode")
        end

        let!(:other_band) do
          Band.create(name: "Tool")
        end

        let(:other) do
          [ other_band ]
        end

        it "returns false" do
          criteria.should_not eq(other)
        end
      end
    end

    context "when the other is neither a criteria or enumerable" do

      it "returns false" do
        criteria.should_not eq("test")
      end
    end
  end

  describe "#===" do

    context "when the other is a criteria" do

      let(:other) do
        Band.where(name: "Depeche Mode")
      end

      it "returns true" do
        (described_class === other).should be_true
      end
    end

    context "when the other is not a criteria" do

      it "returns false" do
        (described_class === []).should be_false
      end
    end
  end

  [ :all, :all_in ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(genres: [ "electro", "dub" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, genres: [ "electro", "dub" ])
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  [ :and, :all_of ].each do |method|

    describe "\##{method}" do

      let!(:match) do
        Band.create(name: "Depeche Mode", genres: [ "electro" ])
      end

      let!(:non_match) do
        Band.create(genres: [ "house" ])
      end

      let(:criteria) do
        Band.send(method, { genres: "electro" }, { name: "Depeche Mode" })
      end

      it "returns the matching documents" do
        criteria.should eq([ match ])
      end
    end
  end

  describe "#as_json" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "returns the criteria as a json hash" do
      criteria.as_json.should eq([ band.serializable_hash ])
    end
  end

  describe "#between" do

    let!(:match) do
      Band.create(member_count: 3)
    end

    let!(:non_match) do
      Band.create(member_count: 10)
    end

    let(:criteria) do
      Band.between(member_count: 1..5)
    end

    it "returns the matching documents" do
      criteria.should eq([ match ])
    end
  end

  pending "#build"
  pending "#clone"
  pending "#collection"
  pending "#cache"
  pending "#cached?"
  pending "#context"
  pending "#create"
  pending "#documents"
  pending "#documents="
  pending "#each"

  pending "#elem_match"

  pending "#execute_or_raise"

  pending "#exists"
  pending "#exists?"

  pending "#explain"
  pending "#extract_id"
  pending "#find"
  pending "#for_ids"
  pending "#freeze"
  pending "#from_map_or_db"

  pending "$gt"
  pending "$gte"

  pending "#in"
  pending "#any_in"

  pending "#initialize"
  pending "#includes"
  pending "#inclusions"
  pending "#inclusions="

  pending "#lt"
  pending "#lte"
  pending "#max_distance"

  pending "#merge"
  pending "#merge!"

  pending "#mod"
  pending "#ne"
  pending "#near"
  pending "#near_sphere"
  pending "#nin"
  pending "#nor"
  pending "#only"

  pending "#or"
  pending "#any_of"

  pending "#respond_to?"
  pending "#to_ary"
  pending "#to_criteria"
  pending "#to_proc"
  pending "#type"

  pending "#where"
  pending "#within_box"
  pending "#within_circle"
  pending "#within_polygon"
  pending "#within_spherical_circle"

  pending "#with_size"
  pending "#with_type"
end
