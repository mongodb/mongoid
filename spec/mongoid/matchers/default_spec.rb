require "spec_helper"

describe Mongoid::Matchers::Default do

  describe "#matches?" do

    context "when comparing strings" do

      let(:matcher) do
        described_class.new("Testing")
      end

      context "when the values are equal" do

        it "returns true" do
          expect(matcher.matches?("Testing")).to be_true
        end
      end

      context "when the values are not equal" do

        it "returns false" do
          expect(matcher.matches?("Other")).to be_false
        end
      end
    end

    context "when comparing object ids" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:matcher) do
        described_class.new(object_id)
      end

      context "when the values are equal" do

        it "returns true" do
          expect(matcher.matches?(object_id)).to be_true
        end
      end

      context "when the values are not equal" do

        it "returns false" do
          expect(matcher.matches?(Moped::BSON::ObjectId.new)).to be_false
        end
      end
    end

    context "when comparing a string to an array" do

      let(:matcher) do
        described_class.new(["Test1", "Test2", "Test3"])
      end

      context "when the attribute contains the value" do

        context "when the value is a string" do

          it "returns true" do
            expect(matcher.matches?("Test1")).to be_true
          end
        end

        context "when the value is a regexp" do

          it "returns true" do
            expect(matcher.matches?(/^Test[3-5]$/)).to be_true
          end
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          expect(matcher.matches?("Test4")).to be_false
        end
      end
    end

    context "when comparing an object id to an array" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:matcher) do
        described_class.new([ object_id, Moped::BSON::ObjectId.new ])
      end

      context "when the attribute contains the value" do

        it "returns true" do
          expect(matcher.matches?(object_id)).to be_true
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          expect(matcher.matches?(Moped::BSON::ObjectId.new)).to be_false
        end
      end
    end

    context "when comparing an array to an array" do

      let(:matcher) do
        described_class.new(["Test1", "Test2", "Test3"])
      end

      context "when the attribute contains the value" do

        it "returns true" do
          expect(matcher.matches?(["Test1", "Test2", "Test3"])).to be_true
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          expect(matcher.matches?(["Test1", "Test2"])).to be_false
        end
      end
    end
  end
end
