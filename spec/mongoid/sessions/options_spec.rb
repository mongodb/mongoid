require "spec_helper"

describe Mongoid::Sessions::Options do

#  class Foo
#    include Mongoid::Sessions::Options
#  end

  describe "#with" do

    context "when passing some options" do

      let(:options) { { database: 'test' } }

      let(:klass) do
        Band.with(options)
      end

      it "sets the options into the class" do
        expect(klass.persistence_options).to eq(options)
      end

      it "sets the options into the instance" do
        expect(klass.new.persistence_options).to eq(options)
      end

      context "when calling .collection method" do

        before do
          klass.collection
        end

        it "keeps the options" do
          expect(klass.persistence_options).to eq(options)
        end
      end
    end
  end

  describe ".with" do

    let(:options) { { database: 'test' } }

    let(:instance) do
      Band.new.with(options)
    end

    it "sets the options into" do
      expect(instance.persistence_options).to eq(options)
    end

    it "passes down the options to collection" do
      Band.should_receive(:collection).with(options)
      instance.collection
    end
  end
end
