require "spec_helper"

describe Mongoid::Sessions::Options do

  describe "#with" do

    context "when passing some options" do

      let(:options) { { database: 'test' } }

      let!(:klass) do
        Band.with(options)
      end

      it "sets the options into the class" do
        expect(klass.persistence_options).to eq(options)
      end

      it "sets the options into the instance" do
        expect(klass.new.persistence_options).to eq(options)
      end

      it "doesnt set the options on class level" do
        expect(Band.new.persistence_options).to be_nil
      end

      context "when calling .collection method" do

        before do
          klass.collection
        end

        it "keeps the options" do
          expect(klass.persistence_options).to eq(options)
        end
      end

      context "when returning a criteria" do

        let(:criteria) do
          klass.all
        end

        it "sets the options into the criteria object" do
          expect(criteria.persistence_options).to eq(options)
        end

        it "doesnt set the options on class level" do
          expect(Band.new.persistence_options).to be_nil
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
      expect_any_instance_of(Moped::Session).to receive(:with).with(options).and_return({})
      instance.collection
    end
  end

  describe "#persistence_options" do

    it "touches the thread local" do
      expect(Thread.current).to receive(:[]).with("[mongoid][Band]:persistence-options").and_return({foo: :bar})
      expect(Band.persistence_options).to eq({foo: :bar})
    end

    it "cannot force a value on thread local" do
      expect {
        Band.set_persistence_options(Band, {})
      }.to raise_error(NoMethodError)
    end
  end

  describe ".persistence_options" do

    context "when options exist on the current thread" do

      let(:klass) do
        Band.with(write: { w: 2 })
      end

      it "returns the options" do
        expect(klass.persistence_options).to eq(write: { w: 2 })
      end
    end

    context "when there are no options on the current thread" do

      it "returns nil" do
        expect(Band.persistence_options).to be_nil
      end
    end
  end
end
