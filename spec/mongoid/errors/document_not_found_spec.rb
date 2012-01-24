require "spec_helper"

describe Mongoid::Errors::DocumentNotFound do
  let(:klass) { Person }
  let(:summary) do
    "When calling #{klass}.find() with an id or array of ids, " +
    "each parameter must match a document in the database " +
    "or this error will be raised."
  end
  let(:resolution) do
    "a) Search for an id that is in the database.\n  "+
    "b) Set the Mongoid.raise_not_found_error configuration "+
    "option to false, which will cause a nil to be "+
    "returned instead of raising this error."
  end

  describe "#problem" do
    context "when providing an id" do
      let(:error) { described_class.new(klass, "3") }
      let(:problem) do
        "Document not found for class #{klass} with id(s) 3."
      end

      it "contains a description of the problem" do
        error.send(:problem).should eq(problem)
      end
    end

    context "when providing ids" do
      let(:error) { described_class.new(klass, [ 1, 2, 3 ]) }
      let(:problem) do
        "Document not found for class #{klass} with id(s) [1, 2, 3]."
      end

      it "contains a description of the problem" do
        error.send(:problem).should eq(problem)
      end
    end

    context "when providing attributes" do
      let(:error) { described_class.new(klass, { :foo => "bar" }) }
      let(:problem) do
        "Document not found for class #{klass} with attributes {:foo=>\"bar\"}."
      end

      it "contains a description of the problem" do
        error.send(:problem).should eq(problem)
      end
    end
  end

  describe "#summary" do
    context "providing an id" do
      let(:error) { described_class.new(klass, "3") }

      it "contains a brief summary of the problem" do
        error.send(:summary).should eq(summary)
      end
    end

    context "providing ids" do
      let(:error) { described_class.new(klass, ["1", "2", "3"]) }

      it "contains a brief summary of the problem" do
        error.send(:summary).should eq(summary)
      end
    end

    context "providing attributes" do
      let(:error) { described_class.new(klass, { :foo => :bar }) }

      it "contains a brief summary of the problem" do
        error.send(:summary).should eq(summary)
      end
    end
  end

  describe "#resolution" do
    context "providing an id" do
      let(:error) { described_class.new(klass, "3") }

      it "contains a solution for the problem" do
        error.send(:resolution).should eq(resolution)
      end
    end

    context "providing ids" do
      let(:error) { described_class.new(klass, ["1", "2", "3"]) }

      it "contains a solution for the problem" do
        error.send(:resolution).should eq(resolution)
      end
    end

    context "providing attributes" do
      let(:error) { described_class.new(klass, { :foo => "bar" }) }

      it "contains a solution for the problem" do
        error.send(:resolution).should eq(resolution)
      end
    end
  end

  describe "#message" do
    let(:message) do
      "\nProblem:\n  #{problem}"+
      "\nSummary:\n  #{summary}"+
      "\nResolution:\n  #{resolution}"
    end

    context "when providing an id" do
      let(:error) { described_class.new(klass, "3") }
      let(:problem) do
        "Document not found for class #{klass} with id(s) 3."
      end

      it "contains the whole message" do
        error.send(:message).should eq(message)
      end
    end

    context "when providing ids" do
      let(:error) { described_class.new(klass, [ 1, 2, 3 ]) }
      let(:problem) do
        "Document not found for class #{klass} with id(s) [1, 2, 3]."
      end

      it "contains the whole message" do
        error.send(:message).should eq(message)
      end
    end

    context "when providing attributes" do
      let(:error) { described_class.new(klass, { :foo => "bar" }) }
      let(:problem) do
        "Document not found for class #{klass} with attributes {:foo=>\"bar\"}."
      end

      it "contains the whole message" do
        error.send(:message).should eq(message)
      end
    end
  end
end
