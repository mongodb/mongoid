require "spec_helper"

describe Mongoid::Timestamps::Created::Short do

  describe ".included" do

    let(:quiz) do
      ShortQuiz.new
    end

    let(:fields) do
      ShortQuiz.fields
    end

    before do
      quiz.run_callbacks(:create)
      quiz.run_callbacks(:save)
    end

    it "adds c_at to the document" do
      fields["c_at"].should_not be_nil
    end

    it "does not add u_at to the document" do
      fields["u_at"].should be_nil
    end

    it "does not add the created_at to the document" do
      fields["created_at"].should be_nil
    end

    it "forces the c_at timestamps to UTC" do
      quiz.created_at.should be_within(10).of(Time.now.utc)
    end
  end

  context "when the document is created" do

    let(:quiz) do
      ShortQuiz.create
    end

    it "runs the created callbacks" do
      quiz.created_at.should be_within(10).of(Time.now.utc)
    end

    it "allows access via the raw field" do
      quiz.c_at.should eq(quiz.created_at)
    end
  end
end
