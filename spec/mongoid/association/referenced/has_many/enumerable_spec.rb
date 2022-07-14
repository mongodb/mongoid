# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::HasMany::Enumerable do

  describe "#==" do

    context "when comparing with an enumerable" do

      let(:person) do
        Person.create!
      end

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      context "when only a criteria target exists" do

        let(:criteria) do
          Post.where(person_id: person.id)
        end

        let!(:enumerable) do
          described_class.new(criteria)
        end

        it "returns the equality check" do
          expect(enumerable).to eq([ post ])
        end
      end

      context "when only an array target exists" do

        let!(:enumerable) do
          described_class.new([ post ])
        end

        it "returns the equality check" do
          expect(enumerable._loaded.values).to eq([ post ])
        end
      end

      context "when a criteria and added exist" do

        let(:criteria) do
          Post.where(person_id: person.id)
        end

        let(:enumerable) do
          described_class.new(criteria)
        end

        let(:post_two) do
          Post.new
        end

        context "when the added does not contain unloaded docs" do

          before do
            enumerable << post_two
          end

          it "returns the equality check" do
            expect(enumerable).to eq([ post, post_two ])
          end
        end

        context "when the added contains unloaded docs" do

          before do
            enumerable << post
          end

          it "returns the equality check" do
            expect(enumerable).to eq([ post ])
          end
        end

        context "when the enumerable is loaded" do

          before do
            enumerable.instance_variable_set(:@executed, true)
          end

          context "when the loaded has no docs and added is persisted" do

            before do
              post.save!
              enumerable._added[post.id] = post
            end

            it "returns the equality check" do
              expect(enumerable).to eq([ post ])
            end
          end
        end
      end
    end

    context "when comparing with a non enumerable" do

      let(:enumerable) do
        described_class.new([])
      end

      it "returns false" do
        expect(enumerable).to_not eq("person")
      end
    end
  end

  describe "#===" do

    let(:data) { [] }

    shared_examples 'standard library-compatible enumerable' do
      context "when compared to an array class" do

        it "returns false" do
          expect(enumerable === Array).to be false
        end
      end

      context "when compared to an enumerable class" do

        it "returns false" do
          expect(enumerable === described_class).to be false
        end
      end

      context "when compared to a different class" do

        it "returns false" do
          expect(enumerable === Mongoid::Document).to be false
        end
      end

      context "when compared to an array instance" do

        context "when the entries are equal" do

          let(:data) do
            [Post.new(id: 2)]
          end

          let(:other) do
            described_class.new([Post.new(id: 2)])
          end

          it "returns true" do
            expect(enumerable === other).to be true
          end
        end

        context "when the entries are both empty" do

          let(:other) do
            described_class.new([])
          end

          it "returns true" do
            expect(enumerable === other).to be true
          end
        end

        context "when the entries are not equal" do

          let(:other) do
            described_class.new([ Band.new ])
          end

          it "returns false" do
            expect(enumerable === other).to be false
          end
        end
      end
    end

    context 'enumerable' do
      let(:enumerable) do
        described_class.new(data)
      end

      include_examples 'standard library-compatible enumerable'
    end

    context 'Array instance' do
      let(:enumerable) do
        data
      end

      include_examples 'standard library-compatible enumerable'
    end
  end

  describe "#<<" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new([])
    end

    context "when the association is empty" do

      let!(:added) do
        enumerable << post
      end

      it "adds the document to the added target" do
        expect(enumerable._added).to eq({ post.id => post })
      end

      it "returns the added documents" do
        expect(added).to eq([ post ])
      end

      it "sets the base on the new document" do
        expect_query(0) do
          added.collect(&:person)
        end
      end
    end
  end

  describe "#empty?" do

    let(:person) do
      Person.create!
    end

    let!(:post_one) do
      Post.create!(person_id: person.id)
    end

    let!(:post_two) do
      Post.create!(person_id: person.id)
    end

    context "when only a criteria target exists" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let(:empty) do
        enumerable.empty?
      end

      it "returns false" do
        expect(empty).to be false
      end

      context 'when #empty? is called' do

        before { empty }

        it "retains the correct length" do
          expect(enumerable.length).to eq(2)
        end

        it "retains the correct length when calling to_a" do
          expect(enumerable.to_a.length).to eq(2)
        end

        context "when iterating over the association a second time" do

          before do
            enumerable.each { |post| post }
          end

          it "retains the correct length" do
            expect(enumerable.length).to eq(2)
          end

          it "retains the correct length when calling to_a" do
            expect(enumerable.to_a.length).to eq(2)
          end
        end
      end
    end

    context "when the documents have been loaded" do
      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      before do
        enumerable.load_all!
      end

      it "is _loaded" do
        expect(enumerable._loaded?).to be true
      end

      it "it does not call #exists? on the unloaded scope" do
        expect(enumerable._unloaded).to_not receive(:exists?)
        expect(enumerable.empty?).to be false
      end
    end

    context "when the documents are not loaded" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      it "is not _loaded" do
        expect(enumerable._loaded?).to be false
      end

      it "it calls #exists? on the unloaded scope" do
        expect(enumerable._unloaded).to receive(:exists?)
        expect(enumerable.empty?).to be true
      end

      context "when documents are added" do

        before do
          enumerable << post_one
        end

        it "is not _loaded" do
          expect(enumerable._loaded?).to be false
        end

        it "it does not call #exists? on the unloaded scope" do
          expect(enumerable._unloaded).to_not receive(:exists?)
          expect(enumerable.empty?).to be false
        end
      end
    end
  end

  describe "#any?" do

    let(:person) do
      Person.create!
    end

    let!(:post_one) do
      Post.create!(person_id: person.id)
    end

    let!(:post_two) do
      Post.create!(person_id: person.id)
    end

    context "when only a criteria target exists" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let(:any) do
        enumerable.any?
      end

      it "returns true" do
        expect(any).to be true
      end

      context 'when #any? is called' do

        before { any }

        it "retains the correct length" do
          expect(enumerable.length).to eq(2)
        end

        it "retains the correct length when calling to_a" do
          expect(enumerable.to_a.length).to eq(2)
        end

        context "when iterating over the association a second time" do

          before do
            enumerable.each { |post| post }
          end

          it "retains the correct length" do
            expect(enumerable.length).to eq(2)
          end

          it "retains the correct length when calling to_a" do
            expect(enumerable.to_a.length).to eq(2)
          end
        end
      end
    end

    context "when the documents have been loaded" do
      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      before do
        enumerable.load_all!
      end

      it "is _loaded" do
        expect(enumerable._loaded?).to be true
      end

      it "it does not call #exists? on the unloaded scope" do
        expect(enumerable._unloaded).to_not receive(:exists?)
        expect(enumerable.any?).to be true
      end

      context "when a block is given" do
        it "returns true when the predicate is true" do
          expect(
            enumerable.any? { |doc| true }
          ).to be true
        end

        it "returns false when the predicate is false" do
          expect(
            enumerable.any? { |doc| false }
          ).to be false
        end
      end

      context "when an argument is given" do

        it "returns true when the argument is true" do
          expect(enumerable.any?(Post)).to be true
        end

        it "returns false when the argument is false" do
          expect(enumerable.any?(Sandwich)).to be false
        end
      end

      context "when both an argument and a block are given" do

        it "gives precedence to the pattern" do
          expect(
            enumerable.any?(Post) { |doc| false }
          ).to be true
        end
      end
    end

    context "when the documents are not loaded" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      it "is not _loaded" do
        expect(enumerable._loaded?).to be false
      end

      it "it calls #exists? on the unloaded scope" do
        expect(enumerable._unloaded).to receive(:exists?)
        expect(enumerable.any?).to be false
      end

      context "when documents are added" do

        before do
          enumerable << post_one
        end

        it "is not _loaded" do
          expect(enumerable._loaded?).to be false
        end

        it "it does not call #exists? on the unloaded scope" do
          expect(enumerable._unloaded).to_not receive(:exists?)
          expect(enumerable.any?).to be true
        end
      end

      context "when a block is given" do
        it "returns true when the predicate is true" do
          expect(
            enumerable.any? { |doc| true }
          ).to be true
        end

        it "returns false when the predicate is false" do
          expect(
            enumerable.any? { |doc| false }
          ).to be false
        end
      end

      context "when an argument is given" do

        it "returns true when the argument is true" do
          expect(enumerable.any?(Post)).to be true
        end

        it "returns false when the argument is false" do
          expect(enumerable.any?(Sandwich)).to be false
        end
      end

      context "when both an argument and a block are given" do

        it "gives precedence to the pattern" do
          expect(
            enumerable.any?(Post) { |doc| false }
          ).to be true
        end
      end
    end
  end

  describe "#clear" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person_id: person.id)
    end

    let!(:post_two) do
      Post.create!(person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable._loaded[post.id] = post
      enumerable << post
    end

    let!(:clear) do
      enumerable.clear do |doc|
        expect(doc).to be_a(Post)
      end
    end

    it "clears out the loaded docs" do
      expect(enumerable._loaded).to be_empty
    end

    it "clears out the added docs" do
      expect(enumerable._added).to be_empty
    end

    it "retains its loaded state" do
      expect(enumerable).to_not be__loaded
    end
  end

  describe "#clone" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(title: "one", person_id: person.id)
    end

    let!(:post_two) do
      Post.create!(title: "two", person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable << post
      enumerable << post_two
    end

    let(:cloned) do
      enumerable.clone
    end

    it "does not retain the first id" do
      expect(cloned.first).to_not eq(post)
    end

    it "does not retain the last id" do
      expect(cloned.last).to_not eq(post_two)
    end
  end

  describe "#delete" do

    let(:person) do
      Person.create!
    end

    context "when the document is loaded" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete(post)
      end

      it "deletes the document from the enumerable" do
        expect(enumerable._loaded).to be_empty
      end

      it "returns the document" do
        expect(deleted).to eq(post)
      end
    end

    context "when the document is added" do

      let!(:post) do
        Post.new
      end

      let(:criteria) do
        Person.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      before do
        enumerable << post
      end

      let!(:deleted) do
        enumerable.delete(post)
      end

      it "removes the document from the added docs" do
        expect(enumerable._added).to be_empty
      end

      it "returns the document" do
        expect(deleted).to eq(post)
      end
    end

    context "when the document is unloaded" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let!(:deleted) do
        enumerable.delete(post)
      end

      it "does not load the document" do
        expect(enumerable._loaded).to be_empty
      end

      it "returns the document" do
        expect(deleted).to eq(post)
      end
    end

    context "when the document is not found" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      let(:criteria) do
        Person.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete(Post.new) do |doc|
          expect(doc).to be_nil
        end
      end

      it "returns nil" do
        expect(deleted).to be_nil
      end
    end
  end

  describe "#delete_if" do

    let(:person) do
      Person.create!
    end

    context "when the document is loaded" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == post }
      end

      it "deletes the document from the enumerable" do
        expect(enumerable._loaded).to be_empty
      end

      it "returns the remaining docs" do
        expect(deleted).to be_empty
      end
    end

    context "when the document is added" do

      let!(:post) do
        Post.new
      end

      let(:criteria) do
        Person.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      before do
        enumerable << post
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == post }
      end

      it "removes the document from the added docs" do
        expect(enumerable._added).to be_empty
      end

      it "returns the remaining docs" do
        expect(deleted).to be_empty
      end
    end

    context "when the document is unloaded" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == post }
      end

      it "does not load the document" do
        expect(enumerable._loaded).to be_empty
      end

      it "returns the remaining docs" do
        expect(deleted).to be_empty
      end
    end

    context "when the block doesn't match" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      let(:criteria) do
        Person.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == Post.new }
      end

      it "returns the remaining docs" do
        expect(deleted).to eq([ post ])
      end
    end
  end

  describe "#detect" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person: person, title: "test")
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    context "when setting a value on the matching document" do

      before do
        enumerable.detect{ |post| post.title = "test" }.rating = 10
      end

      it "sets the value on the instance" do
        expect(enumerable.detect{ |post| post.title = "test" }.rating).to eq(10)
      end
    end
  end

  describe "#each" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person_id: person.id)
    end

    context "when only a criteria target exists" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let!(:iterated) do
        enumerable.each do |doc|
          expect(doc).to be_a(Post)
        end
      end

      it "loads each document" do
        expect(enumerable._loaded).to eq({ post.id => post })
      end

      it "becomes loaded" do
        expect(enumerable).to be__loaded
      end

      context 'when the base association is accessed from each document' do

        let(:persons) do
          described_class.new(criteria).collect(&:person)
        end

        before do
          Post.create!(person_id: person.id)
          Post.create!(person_id: person.id)
        end

        it 'sets the base association from the criteria' do
          expect(persons.uniq.size).to eq(1)
        end
      end
    end

    context "when only an array target exists" do

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:iterated) do
        enumerable.each do |doc|
          expect(doc).to be_a(Post)
        end
      end

      it "does not alter the loaded docs" do
        expect(enumerable._loaded).to eq({ post.id => post })
      end

      it "stays loaded" do
        expect(enumerable).to be__loaded
      end
    end

    context "when a criteria and added exist" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let(:post_two) do
        Post.new
      end

      context "when the added does not contain unloaded docs" do

        before do
          enumerable << post_two
        end

        let!(:iterated) do
          enumerable.each do |doc|
            expect(doc).to be_a(Post)
          end
        end

        it "adds the unloaded to the loaded docs" do
          expect(enumerable._loaded).to eq({ post.id => post })
        end

        it "keeps the appended in the added docs" do
          expect(enumerable._added).to eq({ post_two.id => post_two })
        end

        it "stays loaded" do
          expect(enumerable).to be__loaded
        end
      end

      context "when the added contains unloaded docs" do

        before do
          enumerable << post
        end

        let!(:iterated) do
          enumerable.each do |doc|
            expect(doc).to be_a(Post)
          end
        end

        it "adds the persisted added doc to the loaded" do
          expect(enumerable._loaded).to eq({ post.id => post })
        end

        it "stays loaded" do
          expect(enumerable).to be__loaded
        end
      end
    end

    context "when no block is passed" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      it "returns an enumerator" do
        expect(enumerable.each.class.include?(Enumerable)).to be true
      end

    end
  end

  describe "#entries" do

    let(:person) do
      Person.create!
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    context "when the added contains a persisted document" do

      let!(:post) do
        Post.create!(person_id: person.id)
      end

      before do
        enumerable << post
      end

      let(:entries) do
        enumerable.entries
      end

      it "yields to the in memory documents first" do
        expect(entries.first).to equal(post)
      end
    end
  end

  describe "#first" do

    let(:person) do
      Person.create!
    end

    context "when the enumerable is not loaded" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      context "when unloaded is not empty" do

        context "when added is empty" do

          let!(:post) do
            Post.create!(person_id: person.id)
          end

          let(:first) do
            enumerable.first
          end

          it "returns the first unloaded doc" do
            expect(first).to eq(post)
          end

          it "does not load the enumerable" do
            expect(enumerable).to_not be__loaded
          end

          it "receives query only once" do
            expect(criteria).to receive(:first).once
            first
          end
        end

        context "when added is not empty" do

          let!(:post) do
            Post.create!(person_id: person.id)
          end

          let(:post_two) do
            Post.new(person_id: person.id)
          end

          before do
            enumerable << post_two
          end

          let(:first) do
            enumerable.first
          end

          context "when a perviously persisted unloaded doc exists" do

            it "returns the first added doc" do
              expect(first).to eq(post)
            end

            it "does not load the enumerable" do
              expect(enumerable).to_not be__loaded
            end
          end
        end
      end

      context "when unloaded is empty" do

        let!(:post) do
          Post.new(person_id: person.id)
        end

        before do
          enumerable << post
        end

        let(:first) do
          enumerable.first
        end

        it "returns the first loaded doc" do
          expect(first).to eq(post)
        end

        it "does not load the enumerable" do
          expect(enumerable).to_not be__loaded
        end
      end

      context "when unloaded and added are empty" do

        let(:first) do
          enumerable.first
        end

        it "returns nil" do
          expect(first).to be_nil
        end

        it "does not load the enumerable" do
          expect(enumerable).to_not be__loaded
        end
      end
    end

    context "when the enumerable is loaded" do

      context "when loaded is not empty" do

        let!(:post) do
          Post.create!(person_id: person.id)
        end

        let(:enumerable) do
          described_class.new([ post ])
        end

        let(:first) do
          enumerable.first
        end

        it "returns the first loaded doc" do
          expect(first).to eq(post)
        end
      end

      context "when loaded is empty" do

        let!(:post) do
          Post.create!(person_id: person.id)
        end

        let(:enumerable) do
          described_class.new([])
        end

        before do
          enumerable << post
        end

        let(:first) do
          enumerable.first
        end

        it "returns the first added doc" do
          expect(first).to eq(post)
        end
      end

      context "when loaded and added are empty" do

        let(:enumerable) do
          described_class.new([])
        end

        let(:first) do
          enumerable.first
        end

        it "returns nil" do
          expect(first).to be_nil
        end
      end
    end

    context 'when including a limit' do

      let(:person) do
        Person.create!
      end

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      let!(:first_post) do
        person.posts.create!(title: "One")
      end

      let!(:second_post) do
        person.posts.create!(title: "Two")
      end

      it 'returns the matching document' do
        expect(enumerable.first(1)).to eq([first_post])
      end
    end

    context 'when no parameters are provided' do

      let(:person) do
        Person.create!
      end

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      let!(:first_post) do
        person.posts.create!(title: "One")
      end

      let!(:second_post) do
        person.posts.create!(title: "Two")
      end

      it 'uses the sort on id' do
        expect(enumerable.first).to eq(first_post)
      end
    end
  end

  describe "#include?" do

    let(:person) do
      Person.create!
    end

    let!(:post_one) do
      Post.create!(person_id: person.id)
    end

    let!(:post_two) do
      Post.create!(person_id: person.id)
    end

    context "when no criteria exists" do

      context "when the enumerable is loaded" do

        let!(:enumerable) do
          described_class.new([ post_one, post_two ])
        end

        let!(:included) do
          enumerable.include?(post_two)
        end

        it "returns true" do
          expect(included).to be true
        end

        it "retains the correct length" do
          expect(enumerable.length).to eq(2)
        end

        it "retains the correct length when calling to_a" do
          expect(enumerable.to_a.length).to eq(2)
        end
      end

      context "when the enumerable contains an added document" do

        let!(:enumerable) do
          described_class.new([])
        end

        let(:post_three) do
          Post.new(person_id: person)
        end

        before do
          enumerable.push(post_three)
        end

        let!(:included) do
          enumerable.include?(post_three)
        end

        it "returns true" do
          expect(included).to be true
        end
      end
    end

    context "when the document is present and not the first" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let(:included) do
        enumerable.include?(post_two)
      end

      it "returns true" do
        expect(included).to be true
      end

      it "retains the correct length" do
        expect(enumerable.length).to eq(2)
      end

      it "retains the correct length when calling to_a" do
        expect(enumerable.to_a.length).to eq(2)
      end

      context "when iterating over the association a second time" do

        before do
          enumerable.each { |post| post }
        end

        it "retains the correct length" do
          expect(enumerable.length).to eq(2)
        end

        it "retains the correct length when calling to_a" do
          expect(enumerable.to_a.length).to eq(2)
        end
      end
    end
  end

  describe "#initialize" do

    let(:person) do
      Person.new
    end

    context "when provided with a criteria" do

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      it "sets the criteria" do
        expect(enumerable._unloaded).to eq(criteria)
      end

      it "is not loaded" do
        expect(enumerable).to_not be__loaded
      end
    end

    context "when provided an array" do

      let(:post) do
        Post.new
      end

      let(:enumerable) do
        described_class.new([ post ])
      end

      it "does not set a criteria" do
        expect(enumerable._unloaded).to be_nil
      end

      it "is loaded" do
        expect(enumerable).to be__loaded
      end
    end
  end

  describe "#in_memory" do

    let(:person) do
      Person.new
    end

    context "when the enumerable is loaded" do

      let(:post) do
        Post.new
      end

      let(:enumerable) do
        described_class.new([ post ])
      end

      let(:post_two) do
        Post.new
      end

      before do
        enumerable << post_two
      end

      let(:in_memory) do
        enumerable.in_memory
      end

      it "returns the loaded and added docs" do
        expect(in_memory).to eq([ post, post_two ])
      end
    end

    context "when the enumerable is not loaded" do

      let(:post) do
        Post.new(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(Post.where(person_id: person.id))
      end

      let(:post_two) do
        Post.new(person_id: person.id)
      end

      before do
        enumerable << post_two
      end

      let(:in_memory) do
        enumerable.in_memory
      end

      it "returns the added docs" do
        expect(in_memory).to eq([ post_two ])
      end
    end

    context "when passed a block" do

      let(:enumerable) do
        described_class.new(Post.where(person_id: person.id))
      end

      let(:post_two) do
        Post.new(person_id: person.id)
      end

      before do
        enumerable << post_two
      end

      it "yields to each in memory document" do
        enumerable.in_memory do |doc|
          expect(doc).to eq(post_two)
        end
      end
    end
  end

  describe "#is_a?" do

    let(:enumerable) do
      described_class.new(Post.all)
    end

    context "when checking against enumerable" do

      it "returns true" do
        expect(enumerable.is_a?(::Enumerable)).to be true
      end
    end

    context "when checking against array" do

      it "returns true" do
        expect(enumerable.is_a?(Array)).to be true
      end
    end
  end

  describe "#last" do

    let(:person) do
      Person.create!
    end

    context "when the enumerable is not loaded" do

      let(:criteria) do
        Post.asc(:_id).where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      context "when unloaded is not empty" do

        let!(:post) do
          Post.create!(person_id: person.id)
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last unloaded doc" do
          expect(last).to eq(post)
        end

        it "does not load the enumerable" do
          expect(enumerable).to_not be__loaded
        end

        it "receives query only once" do
          expect(criteria).to receive(:last).once
          last
        end
      end

      context "when unloaded is empty" do

        let!(:post) do
          Post.new(person_id: person.id)
        end

        before do
          enumerable << post
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last unloaded doc" do
          expect(last).to eq(post)
        end

        it "does not load the enumerable" do
          expect(enumerable).to_not be__loaded
        end
      end

      context "when unloaded and added are empty" do

        let(:last) do
          enumerable.last
        end

        it "returns nil" do
          expect(last).to be_nil
        end

        it "does not load the enumerable" do
          expect(enumerable).to_not be__loaded
        end
      end

      context "when added is not empty" do

        let!(:post_one) do
          person.posts.create!
        end

        let!(:post_two) do
          person.posts.create!
        end

        let(:last) do
          enumerable.last
        end

        context "when accessing from a reloaded child" do

          it "returns the last document" do
            expect(post_one.reload.person.posts.asc(:_id).last).to eq(post_two)
          end
        end
      end
    end

    context "when the enumerable is loaded" do

      context "when loaded is not empty" do

        let!(:post) do
          Post.create!(person_id: person.id)
        end

        let(:enumerable) do
          described_class.new([ post ])
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last loaded doc" do
          expect(last).to eq(post)
        end
      end

      context "when loaded is empty" do

        let!(:post) do
          Post.create!(person_id: person.id)
        end

        let(:enumerable) do
          described_class.new([])
        end

        before do
          enumerable << post
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last added doc" do
          expect(last).to eq(post)
        end
      end

      context "when loaded and added are empty" do

        let(:enumerable) do
          described_class.new([])
        end

        let(:last) do
          enumerable.last
        end

        it "returns nil" do
          expect(last).to be_nil
        end
      end
    end

    context 'when including a limit' do

      let(:person) do
        Person.create!
      end

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      let!(:first_post) do
        person.posts.create!(title: "One")
      end

      let!(:second_post) do
        person.posts.create!(title: "Two")
      end

      it 'returns the matching document' do
        expect(enumerable.last(1)).to eq([second_post])
      end
    end

    context 'when no parameters are provided' do

      let(:person) do
        Person.create!
      end

      let(:criteria) do
        Post.where(person_id: person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      let!(:first_post) do
        person.posts.create!(title: "One")
      end

      let!(:second_post) do
        person.posts.create!(title: "Two")
      end

      it 'uses the sort on id' do
        expect(enumerable.last).to eq(second_post)
      end
    end
  end

  describe "#kind_of?" do

    let(:enumerable) do
      described_class.new(Post.all)
    end

    context "when checking against enumerable" do

      it "returns true" do
        expect(enumerable.kind_of?(::Enumerable)).to be true
      end
    end

    context "when checking against array" do

      it "returns true" do
        expect(enumerable.kind_of?(Array)).to be true
      end
    end
  end

  describe "#load_all!" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    let!(:loaded) do
      enumerable.load_all!
    end

    it "loads all the unloaded documents" do
      expect(enumerable._loaded).to eq({ post.id => post })
    end

    it "returns the object" do
      expect(loaded).to eq([post])
    end

    it "sets loaded to true" do
      expect(enumerable).to be__loaded
    end
  end

  describe "#reset" do

    let(:person) do
      Person.create!
    end

    let(:post) do
      Post.create!(person_id: person.id)
    end

    let(:post_two) do
      Post.create!(person_id: person.id)
    end

    let(:enumerable) do
      described_class.new([ post ])
    end

    before do
      enumerable << post_two
    end

    let!(:reset) do
      enumerable.reset
    end

    it "is not loaded" do
      expect(enumerable).to_not be__loaded
    end

    it "clears out the loaded docs" do
      expect(enumerable._loaded).to be_empty
    end

    it "clears out the added docs" do
      expect(enumerable._added).to be_empty
    end
  end

  describe "#respond_to?" do

    let(:enumerable) do
      described_class.new([])
    end

    context "when checking against array methods" do

      [].methods.each do |method|

        it "returns true for #{method}" do
          expect(enumerable).to respond_to(method)
        end
      end
    end
  end

  describe "#size" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person_id: person.id)
    end

    context "when the base is new" do

      let!(:person) do
        Person.new
      end

      context "when the added contains a persisted document" do

        let!(:post) do
          Post.create!(person_id: person.id)
        end

        context "when the enumerable is not loaded" do

          let(:enumerable) do
            described_class.new(Post.where(person_id: person.id))
          end

          it "includes the number of all added documents" do
            expect(enumerable.size).to eq(1)
          end
        end
      end
    end

    context "when the enumerable is loaded" do

      let(:enumerable) do
        described_class.new([ post ])
      end

      let(:post_two) do
        Post.new(person_id: person.id)
      end

      before do
        enumerable << post_two
      end

      let(:size) do
        enumerable.size
      end

      it "returns the loaded size plus added size" do
        expect(size).to eq(2)
      end

      it "matches the size of the loaded enumerable" do
        expect(size).to eq(enumerable.to_a.size)
      end
    end

    context "when the enumerable is not loaded" do

      let(:enumerable) do
        described_class.new(Post.where(person_id: person.id))
      end

      context "when the added contains new documents" do

        let(:post_two) do
          Post.new(person_id: person.id)
        end

        before do
          enumerable << post_two
        end

        let(:size) do
          enumerable.size
        end

        it "returns the unloaded count plus added new size" do
          expect(size).to eq(2)
        end
      end

      context "when the added contains persisted documents" do

        let(:post_two) do
          Post.create!(person_id: person.id)
        end

        before do
          enumerable << post_two
        end

        let(:size) do
          enumerable.size
        end

        it "returns the unloaded count plus added new size" do
          expect(size).to eq(2)
        end
      end
    end
  end

  describe "#to_json" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(title: "test", person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable << post
    end

    let!(:json) do
      enumerable.to_json
    end

    it "serializes the enumerable" do
      expect(json).to include(post.title)
    end
  end

  describe "#to_json(parameters)" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(title: "test", person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:json) do
      person.posts.to_json({except: 'title'})
    end

    it "serializes the enumerable" do
      expect(json).to_not include(post.title)
    end
  end

  describe "#as_json" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(title: "test", person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable << post
    end

    let!(:json) do
      enumerable.as_json
    end

    it "serializes the enumerable" do
      expect(json.size).to eq(1)
      expect(json[0]['title']).to eq(post.title)
    end
  end

  describe "#as_json(parameters)" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(title: "test", person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:json) do
      person.posts.as_json({except: "title"})
    end

    it "serializes the enumerable" do
      expect(json.size).to eq(1)
    end

    it "includes the proper fields" do
      expect(json[0].keys).to_not include("title")
    end
  end

  describe "#uniq" do

    let(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(person_id: person.id)
    end

    let(:criteria) do
      Post.where(person_id: person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable << post
      enumerable._loaded[post.id] = post
    end

    let!(:uniq) do
      enumerable.uniq
    end

    it "returns the unique documents" do
      expect(uniq).to eq([ post ])
    end

    it "sets loaded to true" do
      expect(enumerable).to be__loaded
    end
  end

  describe 'setting the same parent object on enumerated children objects' do

    let(:person) do
      Person.create!
    end

    context 'when a single child is fetched' do

      let!(:post) do
        person.posts << Post.new
        person.posts.first
      end

      it 'does not query the database to access the parent' do
        expect_query(0) do
          expect(post.person).to eq(person)
        end
      end
    end

    context 'when a single child is fetched with a scope' do

      let!(:post) do
        person.posts << Post.new(title: 'open')
        person.posts.open.first
      end

      it 'does not query the database to access the parent' do
        expect_query(0) do
          expect(post.person).to eq(person)
        end
      end
    end

    context 'when multiple children are fetched' do

      let!(:posts) do
        person.posts << Post.new
        person.posts << Post.new
        person.posts << Post.new
        person.posts.to_a
      end

      it 'does not query the database to access the parent' do
        expect_query(0) do
          expect(posts.all? { |post| post.person == person }).to be(true)
        end
      end
    end

    context 'when multiple children are fetched with query criteria' do

      let!(:posts) do
        person.posts << Post.new(title: 'open')
        person.posts << Post.new(title: 'open')
        person.posts << Post.new(title: 'not-a-test')
        person.posts.where(title: 'open').to_a
      end

      it 'does not query the database to access the parent' do
        expect_query(0) do
          expect(posts.all? { |post| post.person == person }).to be(true)
        end
      end
    end

    context 'when multiple children are fetched with a scope' do

      let!(:posts) do
        person.posts << Post.new(title: 'open')
        person.posts << Post.new(title: 'open')
        person.posts << Post.new(title: 'not-a-test')
        person.posts.open.to_a
      end

      it 'does not query the database to access the parent' do
        expect_query(0) do
          expect(posts.all? { |post| post.person == person }).to be(true)
        end
      end
    end

    context 'when the parent is updated in memory' do

      let!(:posts) do
        person.posts << Post.new
        person.posts << Post.new
        person.username = 'emily'
        person.posts.to_a
      end

      it 'does not query the database to access the parent' do
        expect_query(0) do
          expect(posts.all? { |post| post.person.username == 'emily' }).to be(true)
        end
      end
    end
  end
end
