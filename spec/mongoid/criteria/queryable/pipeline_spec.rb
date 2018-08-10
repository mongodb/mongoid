# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Pipeline do

  describe "#__deep_copy" do

    let(:project) do
      { "$project" => { "name" => 1 }}
    end

    let(:pipeline) do
      described_class.new
    end

    before do
      pipeline.push(project)
    end

    let(:copied) do
      pipeline.__deep_copy__
    end

    it "clones all the objects in the pipeline" do
      expect(copied.first).to_not equal(project)
    end

    it "clones the pipeline" do
      expect(copied).to_not equal(pipeline)
    end
  end

  describe "#group" do

    context "when the expression fields are not aliased" do

      let(:pipeline) do
        described_class.new
      end

      context "when using full notation" do

        before do
          pipeline.group(count: { "$sum" => 1 }, max: { "$max" => "likes" })
        end

        it "adds the group operation to the pipeline" do
          expect(pipeline).to eq([
            { "$group" => { "count" => { "$sum" => 1 }, "max" => { "$max" => "likes" }}}
          ])
        end
      end

      context "when using symbol shortcuts" do

        before do
          pipeline.group(:count.sum => 1, :max.max => "likes")
        end

        it "adds the group operation to the pipeline" do
          expect(pipeline).to eq([
            { "$group" => { "count" => { "$sum" => 1 }, "max" => { "$max" => "likes" }}}
          ])
        end
      end
    end
  end

  describe "#initialize" do

    context "when provided aliases" do

      let(:aliases) do
        { "id" => "_id" }
      end

      let(:pipeline) do
        described_class.new(aliases)
      end

      it "sets the aliases" do
        expect(pipeline.aliases).to eq(aliases)
      end
    end

    context "when not provided aliases" do

      let(:pipeline) do
        described_class.new
      end

      it "sets the aliases to an empty hash" do
        expect(pipeline.aliases).to be_empty
      end
    end
  end

  describe "#project" do

    let(:pipeline) do
      described_class.new("id" => "_id")
    end

    context "when the field is not aliased" do

      before do
        pipeline.project(name: 1)
      end

      it "sets the aliased projection" do
        expect(pipeline).to eq([
          { "$project" => { "name" => 1 }}
        ])
      end
    end

    context "when the field is aliased" do

      before do
        pipeline.project(id: 1)
      end

      it "sets the aliased projection" do
        expect(pipeline).to eq([
          { "$project" => { "_id" => 1 }}
        ])
      end
    end
  end

  describe "#unwind" do

    let(:pipeline) do
      described_class.new("alias" => "a")
    end

    context "when provided a symbol" do

      context "when the symbol begins with $" do

        before do
          pipeline.unwind(:$author)
        end

        it "converts the symbol to a string" do
          expect(pipeline).to eq([{ "$unwind" => "$author" }])
        end
      end

      context "when the symbol does not begin with $" do

        before do
          pipeline.unwind(:author)
        end

        it "converts the symbol to a string and prepends $" do
          expect(pipeline).to eq([{ "$unwind" => "$author" }])
        end
      end
    end

    context "when provided a string" do

      context "when the string begins with $" do

        before do
          pipeline.unwind("$author")
        end

        it "sets the string" do
          expect(pipeline).to eq([{ "$unwind" => "$author" }])
        end
      end

      context "when the string does not begin with $" do

        before do
          pipeline.unwind(:author)
        end

        it "prepends $ to the string" do
          expect(pipeline).to eq([{ "$unwind" => "$author" }])
        end
      end
    end

    context "when provided a string alias" do

      context "when the string does not begin with $" do

        before do
          pipeline.unwind(:alias)
        end

        it "prepends $ to the string" do
          expect(pipeline).to eq([{ "$unwind" => "$a" }])
        end
      end
    end

    context "when provided a hash" do
      before do
        pipeline.unwind(path: "$author", "includeArrayIndex" => "author_index", preserveNullAndEmptyArrays: true)
      end

      it "sets the hash" do
        expect(pipeline).to eq([
          { "$unwind" => { path: "$author", "includeArrayIndex" => "author_index", preserveNullAndEmptyArrays: true } }
        ])
      end
    end
  end
end
