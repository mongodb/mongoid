require "spec_helper"

describe Mongoid::Clients::Options do

  describe "#with", if: non_legacy_server? do

    context "when passing some options" do

      let(:options) { { database: 'test' } }

      let!(:cluster) do
        Band.mongo_client.cluster
      end

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

      context 'when passed a block', if: testing_locally? do

        let!(:connections_before) do
          Band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        before do
          Band.with(options) do |klass|
            klass.where(name: 'emily').to_a
          end
        end

        let(:connections_after) do
          Band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        context 'when a new cluster is created by the driver' do

          let(:options) { { connect_timeout: 2 } }

          it 'disconnects the new cluster' do
            expect(connections_after).to eq(connections_before)
          end
        end

        context 'when the same cluster is used by the new client' do

          let(:options) { { database: 'same-cluster' } }

          it 'does not disconnect the original cluster' do
            expect(connections_after).to eq(connections_before)
          end
        end
      end

      context "when calling .collection method" do

        before do
          klass.collection
        end

        it "keeps the options" do
          expect(klass.persistence_options).to eq(options)
        end

        context 'when changing the collection' do

          let(:options) do
            { collection: 'other' }
          end

          it 'uses that collection' do
            expect(klass.collection.name).to eq(options[:collection])
          end
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

  describe ".with", if: non_legacy_server? do

    let(:options) { { database: 'test' } }

    let(:instance) do
      Band.new.with(options)
    end

    it "sets the options into" do
      expect(instance.persistence_options).to eq(options)
    end

    it "passes down the options to collection" do
      expect(instance.collection.database.name).to eq('test')
    end

    context "when the object is shared between threads" do

      before do
        threads = []
        doc = Band.create(name: "Beatles")
        100.times do |i|
          threads << Thread.new do
            if i % 2 == 0
              doc.with(nil).set(name: "Rolling Stones")
            else
              doc.with(options).set(name: "Beatles")
            end
          end
        end
        threads.join
      end

      it "does not share the persistence options" do
        expect(Band.persistence_options).to eq(nil)
      end
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
