require "spec_helper"

describe Mongoid::Timestamps::Created do

  describe ".included" do

    let(:quiz) do
      Quiz.new
    end

    let(:fields) do
      Quiz.fields
    end

    before do
      quiz.run_callbacks(:create)
      quiz.run_callbacks(:save)
    end

    it "adds created_at to the document" do
      fields["created_at"].should_not be_nil
    end

    it "does not add updated_at to the document" do
      fields["updated_at"].should be_nil
    end

    it "forces the created_at timestamps to UTC" do
      quiz.created_at.should be_within(10).of(Time.now.utc)
    end
  end

  context "when the document is created" do

    let(:quiz) do
      Quiz.create
    end

    it "runs the created callbacks" do
      quiz.created_at.should_not be_nil
      quiz.created_at.should be_within(10).of(Time.now.utc)
    end
  end
end
