require "spec_helper"

describe Mongoid::Contextual::Mongo do

  [ :blank?, :empty? ].each do |method|

    describe "##{method}" do

      before do
        Band.create(name: "Depeche Mode")
      end

      context "when the count is zero" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns true" do
          expect(context.send(method)).to be true
        end
      end

      context "when the count is greater than zero" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns false" do
          expect(context.send(method)).to be false
        end
      end
    end
  end

  describe "#cached?" do

    context "when the criteria is cached" do

      let(:criteria) do
        Band.all.cache
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns true" do
        expect(context).to be_cached
      end
    end

    context "when the criteria is not cached" do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns false" do
        expect(context).to_not be_cached
      end
    end
  end

  describe "#count" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when no arguments are provided" do

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the number of documents that match" do
        expect(context.count).to eq(1)
      end
    end

    context "when context is cached" do

      let(:context) do
        described_class.new(criteria.cache)
      end

      before do
        expect(context.view).to receive(:count).once.and_return(1)
      end

      it "returns the count cached value after first call" do
        2.times { expect(context.count).to eq(1) }
      end
    end

    context "when provided a document" do

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count(depeche)
      end

      it "returns the number of documents that match" do
        expect(count).to eq(1)
      end
    end

    context "when provided a block" do

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count do |doc|
          doc.likes.nil?
        end
      end

      it "returns the number of documents that match" do
        expect(count).to eq(1)
      end

      context "and a limit true" do

        before do
          2.times { Band.create(name: "Depeche Mode", likes: 1) }
        end

        let(:count) do
          context.count(true) do |doc|
            doc.likes.nil?
          end
        end

        it "returns the number of documents that match" do
          expect(count).to eq(1)
        end
      end
    end

    context "when provided limit" do

      before do
        2.times { Band.create(name: "Depeche Mode") }
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count(limit: 2)
      end

      it "returns the number of documents that match" do
        expect(count).to eq(2)
      end
    end
  end

  [ :delete, :delete_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the selector is contraining" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:deleted) do
          context.send(method)
        end

        it "deletes the matching documents" do
          expect(Band.find(new_order.id)).to eq(new_order)
        end

        it "deletes the correct number of documents" do
          expect(Band.count).to eq(1)
        end

        it "returns the number of documents deleted" do
          expect(deleted).to eq(1)
        end
      end

      context "when the selector is not contraining" do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end

        before do
          context.send(method)
        end

        it "deletes all the documents" do
          expect(Band.count).to eq(0)
        end
      end
    end
  end

  [ :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the selector is contraining" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:destroyed) do
          context.send(method)
        end

        it "destroys the matching documents" do
          expect(Band.find(new_order.id)).to eq(new_order)
        end

        it "destroys the correct number of documents" do
          expect(Band.count).to eq(1)
        end

        it "returns the number of documents destroyed" do
          expect(destroyed).to eq(1)
        end
      end

      context "when the selector is not contraining" do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end

        before do
          context.send(method)
        end

        it "destroys all the documents" do
          expect(Band.count).to eq(0)
        end
      end
    end
  end

  describe "#distinct" do

    before do
      Band.create(name: "Depeche Mode", years: 30)
      Band.create(name: "New Order", years: 25)
    end

    context "when limiting the result set" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct matching fields" do
        expect(context.distinct(:name)).to eq([ "Depeche Mode" ])
      end
    end

    context "when not limiting the result set" do

      let(:criteria) do
        Band.criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct field values" do
        expect(context.distinct(:name)).to eq([ "Depeche Mode", "New Order" ])
      end
    end

    context "when providing an aliased field" do

      let(:criteria) do
        Band.criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct field values" do
        expect(context.distinct(:years)).to eq([ 30, 25 ])
      end
    end
  end

  describe "#each" do

    before do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing a block" do

      it "yields mongoid documents to the block" do
        context.each do |doc|
          expect(doc).to be_a(Mongoid::Document)
        end
      end

      it "iterates over the matching documents" do
        context.each do |doc|
          expect(doc.name).to eq("Depeche Mode")
        end
      end

      it "returns self" do
        expect(context.each{}).to be(context)
      end
    end

    context "when no block is provided" do

      let(:enum) do
        context.each
      end

      it "returns an enumerator" do
        expect(enum).to be_a(Enumerator)
      end

      context "when iterating over the enumerator" do

        context "when iterating with each" do

          it "yields mongoid documents to the block" do
            enum.each do |doc|
              expect(doc).to be_a(Mongoid::Document)
            end
          end
        end

        context "when iterating with next" do

          it "yields mongoid documents" do
            expect(enum.next).to be_a(Mongoid::Document)
          end
        end
      end
    end
  end

  describe "#eager_load" do

    let(:criteria) do
      Person.includes(:game)
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when no documents are returned" do

      let(:game_metadata) do
        Person.reflect_on_association(:game)
      end

      it "does not make any additional database queries" do
        expect(game_metadata).to receive(:eager_load).never
        context.send(:eager_load, [])
      end
    end
  end

  describe "#exists?" do

    before do
      Band.create(name: "Depeche Mode")
    end

    context "when the count is zero" do

      let(:criteria) do
        Band.where(name: "New Order")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns false" do
        expect(context).to_not be_exists
      end
    end

    context "when the count is greater than zero" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns true" do
        expect(context).to be_exists
      end
    end

    context "when caching is not enabled" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when exists? already called" do

        before do
          context.exists?
        end

        it "hits the database again" do
          expect(context).to receive(:view).once.and_call_original
          expect(context).to be_exists
        end
      end
    end

    context "when caching is enabled" do

      let(:criteria) do
        Band.where(name: "Depeche Mode").cache
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when the cache is loaded" do

        before do
          context.to_a
        end

        it "does not hit the database" do
          expect(context).to receive(:view).never
          expect(context).to be_exists
        end
      end

      context "when the cache is not loaded" do

        context "when a count has been executed" do

          before do
            context.count
          end

          it "does not hit the database" do
            expect(context).to receive(:view).never
            expect(context).to be_exists
          end
        end
      end
    end
  end

  describe "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "returns the criteria explain path" do
      expect(context.explain).to_not be_empty
    end
  end

  describe "#find_one_and_update" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create(name: "Tool")
    end

    context "when the selector matches" do

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(tool)
        end

        it "updates the document in the database" do
          expect(tool.reload.likes).to eq(1)
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "limits the returned fields" do
          expect(result.name).to be_nil
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update({ "$inc" => { likes: 1 }}, return_document: :after)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "returns the updated document" do
          expect(result.likes).to eq(1)
        end
      end

      context "when removing" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_delete
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "deletes the document from the database" do
          expect {
            depeche.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:result) do
        context.find_one_and_update("$inc" => { likes: 1 })
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the context is not cached" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the first matching document" do
          expect(context.send(method)).to eq(depeche_mode)
        end
      end

      context "when using .desc" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when there is sort on the context" do

          it "follows the main sort" do
            expect(context.send(method)).to eq(new_order)
          end
        end

        context "when subsequently calling #last" do

          it "returns the correct document" do
            expect(context.send(method)).to eq(new_order)
            expect(context.last).to eq(depeche_mode)
          end
        end
      end

      context "when using .sort" do

        let(:criteria) do
          Band.all.sort(:name => -1).criteria
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when there is sort on the context" do

          it "follows the main sort" do
            expect(context.send(method)).to eq(new_order)
          end
        end

        context "when subsequently calling #last" do

          it "returns the correct document" do
            expect(context.send(method)).to eq(new_order)
            expect(context.last).to eq(depeche_mode)
          end
        end
      end

      context "when the context is cached" do

        let(:criteria) do
          Band.where(name: "Depeche Mode").cache
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when the cache is loaded" do

          before do
            context.to_a
          end

          it "returns the first document without touching the database" do
            expect(context).to receive(:view).never
            expect(context.send(method)).to eq(depeche_mode)
          end
        end

        context "when first method was called before" do

          before do
            context.first
          end

          it "returns the first document without touching the database" do
            expect(context).to receive(:view).never
            expect(context.send(method)).to eq(depeche_mode)
          end
        end
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      Band.where(name: "Depeche Mode").no_timeout
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sets the criteria" do
      expect(context.criteria).to eq(criteria)
    end

    it "sets the klass" do
      expect(context.klass).to eq(Band)
    end

    it "sets the view" do
      expect(context.view).to be_a(Mongo::Collection::View)
    end

    it "sets the view selector" do
      expect(context.view.selector).to eq({ "name" => "Depeche Mode" })
    end
  end

  [ :length, :size ].each do |method|

    describe "##{method}" do

      before do
        Band.create(name: "Depeche Mode")
        Band.create(name: "New Order")
      end

      context "when the criteria has a limit" do

        let(:criteria) do
          Band.limit(1)
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the number of documents that match" do
          expect(context.send(method)).to eq(2)
        end

        context "when calling more than once" do

          before do
            expect(context.view).to receive(:count).once.and_return(2)
          end

          it "returns the cached value for subsequent calls" do
            2.times { expect(context.send(method)).to eq(2) }
          end
        end

        context "when the results have been iterated over" do

          before do
            context.entries
            expect(context.view).to receive(:count).once.and_return(2)
          end

          it "returns the cached value for all calls" do
            expect(context.send(method)).to eq(2)
          end

          context "when the results have been iterated over multiple times" do

            before do
              context.entries
            end

            it "resets the length on each full iteration" do
              expect(context.size).to eq(2)
            end
          end
        end
      end

      context "when the criteria has no limit" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the number of documents that match" do
          expect(context.send(method)).to eq(1)
        end

        context "when calling more than once" do

          before do
            expect(context.view).to receive(:count).once.and_return(1)
          end

          it "returns the cached value for subsequent calls" do
            2.times { expect(context.send(method)).to eq(1) }
          end
        end

        context "when the results have been iterated over" do

          before do
            context.entries
            expect(context.view).to receive(:count).once.and_return(1)
          end

          it "returns the cached value for all calls" do
            expect(context.send(method)).to eq(1)
          end

          context "when the results have been iterated over multiple times" do

            before do
              context.entries
            end

            it "resets the length on each full iteration" do
              expect(context.size).to eq(1)
            end
          end
        end
      end
    end
  end

  describe "#limit" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      expect(context.limit(1).entries).to eq([ depeche_mode ])
    end
  end

  describe "#map" do

    before do
      Band.create(name: "Depeche Mode")
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when passed the symbol field name" do

      it "limits query to that field" do
        expect(criteria).to receive(:only).with(:name).and_call_original
        context.map(:name)
      end

      it "performs mapping" do
        expect(context.map(:name)).to eq ["Depeche Mode", "New Order"]
      end
    end

    context "when passed a block" do

      it "performs mapping" do
        expect(context.map(&:name)).to eq ["Depeche Mode", "New Order"]
      end
    end
  end

  describe "#map_reduce" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode", likes: 200)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 100)
    end

    let(:map) do
      %Q{
      function() {
        emit(this.name, { likes: this.likes });
      }}
    end

    let(:reduce) do
      %Q{
      function(key, values) {
        var result = { likes: 0 };
        values.forEach(function(value) {
          result.likes += value.likes;
        });
        return result;
      }}
    end

    context "when no selection is provided" do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the second aggregate result" do
        expect(results).to include(
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(2)
      end

      it "contains the entire raw results" do
        expect(results["results"]).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end

      it "contains the execution time" do
        expect(results.time).to_not be_nil
      end

      it "contains the count statistics" do
        expect(results["counts"]).to eq({
          "input" => 2, "emit" => 2, "reduce" => 0, "output" => 2
        })
      end

      it "contains the input count" do
        expect(results.input).to eq(2)
      end

      it "contains the emitted count" do
        expect(results.emitted).to eq(2)
      end

      it "contains the reduced count" do
        expect(results.reduced).to eq(0)
      end

      it "contains the output count" do
        expect(results.output).to eq(2)
      end
    end

    context "when selection is provided" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "includes the aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire raw results" do
        expect(results["results"]).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end

      it "contains the execution time" do
        expect(results.time).to_not be_nil
      end

      it "contains the count statistics" do
        expect(results["counts"]).to eq({
          "input" => 1, "emit" => 1, "reduce" => 0, "output" => 1
        })
      end

      it "contains the input count" do
        expect(results.input).to eq(1)
      end

      it "contains the emitted count" do
        expect(results.emitted).to eq(1)
      end

      it "contains the reduced count" do
        expect(results.reduced).to eq(0)
      end

      it "contains the output count" do
        expect(results.output).to eq(1)
      end
    end

    context "when sorting is provided" do

      before do
        Band.index(name: -1)
        Band.create_indexes
      end

      let(:criteria) do
        Band.desc(:name)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        expect(results).to include(
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        )
      end

      it "returns the second aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(2)
      end

      it "contains the entire raw results" do
        expect(results["results"]).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end

    context "when limiting is provided" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire raw results" do
        expect(results["results"]).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is replace" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(replace: "mr-output")
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is reduce" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(reduce: :mr_output)
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is merge" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(merge: :mr_output)
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when providing no output" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce)
      end

      it "raises an error" do
        expect {
          results.entries
        }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
      end
    end

    context "when providing a finalize" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:finalize) do
        %Q{
        function(key, value) {
          value.extra = true;
          return value;
        }}
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1).finalize(finalize)
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200, "extra" => true }}
        ])
      end
    end
  end

  describe "#skip" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      expect(context.skip(1).entries).to eq([ new_order ])
    end
  end

  describe "#sort" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing a spec" do

      it "sorts the results" do
        expect(context.sort(name: -1).entries).to eq([ new_order, depeche_mode ])
      end

      it "returns the context" do
        expect(context.sort(name: 1)).to eq(context)
      end
    end

    context "when providing a block" do

      let(:sorted) do
        context.sort do |a, b|
          b.name <=> a.name
        end
      end

      it "sorts the results in memory" do
        expect(sorted).to eq([ new_order, depeche_mode ])
      end
    end
  end

  describe "#update" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when adding an element to a HABTM set" do

      let(:person) do
        Person.create
      end

      let(:preference) do
        Preference.create
      end

      before do
        Person.where(id: person.id).
          update("$addToSet" => { preference_ids: preference.id })
      end

      it "adds a single element to the array" do
        expect(person.reload.preference_ids).to eq([ preference.id ])
      end
    end

    context "when providing attributes" do

      context "when the attributes are of the correct type" do

        before do
          context.update(name: "Smiths")
        end

        it "updates only the first matching document" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "does not update the last matching document" do
          expect(new_order.reload.name).to eq("New Order")
        end
      end

      context "when the attributes must be mongoized" do

        context "when coercing a string to integer" do

          before do
            context.update(member_count: "1")
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.member_count).to eq(1)
          end

          it "does not update the last matching document" do
            expect(new_order.reload.member_count).to be_nil
          end
        end

        context "when coercing a string to date" do

          before do
            context.update(founded: "1979/1/1")
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.founded).to eq(Date.new(1979, 1, 1))
          end

          it "does not update the last matching document" do
            expect(new_order.reload.founded).to be_nil
          end
        end
      end
    end

    context "when providing atomic operations" do

      context "when only atomic operations are provided" do

        context "when the attributes are in the correct type" do

          before do
            context.update("$set" => { name: "Smiths" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.name).to eq("Smiths")
          end

          it "does not update the last matching document" do
            expect(new_order.reload.name).to eq("New Order")
          end
        end

        context "when the attributes must be mongoized" do

          before do
            context.update("$set" => { member_count: "1" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.member_count).to eq(1)
          end

          it "does not update the last matching document" do
            expect(new_order.reload.member_count).to be_nil
          end
        end
      end

      context "when a mix are provided" do

        before do
          context.update("$set" => { name: "Smiths" }, likes: 100)
        end

        it "updates the first matching document's set" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "updates the first matching document's updates" do
          expect(depeche_mode.reload.likes).to eq(100)
        end

        it "does not update the last matching document's set" do
          expect(new_order.reload.name).to eq("New Order")
        end

        it "does not update the last matching document's updates" do
          expect(new_order.reload.likes).to be_nil
        end
      end
    end

    context "when providing no attributes" do

      it "returns false" do
        expect(context.update).to be false
      end
    end
  end

  describe "#update_all" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode", origin: "Essex")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing attributes" do

      context "when the attributes are of the correct type" do

        before do
          context.update_all(name: "Smiths")
        end

        it "updates the first matching document" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "does not clear out other attributes" do
          expect(depeche_mode.reload.origin).to eq("Essex")
        end

        it "updates the last matching document" do
          expect(new_order.reload.name).to eq("Smiths")
        end
      end

      context "when the attributes must be mongoized" do

        before do
          context.update_all(member_count: "1")
        end

        it "updates the first matching document" do
          expect(depeche_mode.reload.member_count).to eq(1)
        end

        it "updates the last matching document" do
          expect(new_order.reload.member_count).to eq(1)
        end
      end

      context "when using aliased field names" do

        before do
          context.update_all(years: 100)
        end

        it "updates the first matching document" do
          expect(depeche_mode.reload.years).to eq(100)
        end

        it "updates the last matching document" do
          expect(new_order.reload.years).to eq(100)
        end
      end
    end

    context "when providing atomic operations" do

      context "when only atomic operations are provided" do

        context "when the attributes are in the correct type" do

          before do
            context.update_all("$set" => { name: "Smiths" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.name).to eq("Smiths")
          end

          it "updates the last matching document" do
            expect(new_order.reload.name).to eq("Smiths")
          end
        end

        context "when the attributes must be mongoized" do

          before do
            context.update_all("$set" => { member_count: "1" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.member_count).to eq(1)
          end

          it "updates the last matching document" do
            expect(new_order.reload.member_count).to eq(1)
          end
        end
      end

      context "when a mix are provided" do

        before do
          context.update_all("$set" => { name: "Smiths" }, likes: 100)
        end

        it "updates the first matching document's set" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "updates the first matching document's updates" do
          expect(depeche_mode.reload.likes).to eq(100)
        end

        it "updates the last matching document's set" do
          expect(new_order.reload.name).to eq("Smiths")
        end

        it "updates the last matching document's updates" do
          expect(new_order.reload.likes).to eq(100)
        end
      end
    end

    context "when providing no attributes" do

      it "returns false" do
        expect(context.update_all).to be false
      end
    end
  end

  describe '#pipeline' do

    context 'when the criteria has a selector' do

      let(:criteria) do
        Band.where(name: "New Order")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:matches_operators) do
        context.send(:pipeline, 'name').select { |o| o['$match'] }
      end

      it 'creates a pipeline with the selector as one of the $match criteria' do
        expect(matches_operators).to include('$match' => criteria.selector)
      end

      it 'creates a pipeline with the $exists operator as one of the $match criteria' do
        expect(matches_operators).to include('$match' => { 'name' => { '$exists' => true } })
      end
    end
  end
end
