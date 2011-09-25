require "spec_helper"

describe Mongoid::Relations::Targets::Enumerable do

  before do
    [ Person, Post ].each(&:delete_all)
  end

  describe "#==" do

    context "when comparing with an enumerable" do

      let(:person) do
        Person.create(:ssn => "543-98-1234")
      end

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      context "when only a criteria target exists" do

        let(:criteria) do
          Post.where(:person_id => person.id)
        end

        let!(:enumerable) do
          described_class.new(criteria)
        end

        it "returns the equality check" do
          enumerable.should eq([ post ])
        end
      end

      context "when only an array target exists" do

        let!(:enumerable) do
          described_class.new([ post ])
        end

        it "returns the equality check" do
          enumerable.loaded.should eq([ post ])
        end
      end

      context "when a criteria and added exist" do

        let(:criteria) do
          Post.where(:person_id => person.id)
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
            enumerable.should eq([ post, post_two ])
          end
        end

        context "when the added contains unloaded docs" do

          before do
            enumerable << post
          end

          it "returns the equality check" do
            enumerable.should eq([ post ])
          end
        end

        context "when the enumerable is loaded" do

          before do
            enumerable.instance_variable_set(:@executed, true)
          end

          context "when the loaded has no docs and added is persisted" do

            before do
              post.save
              enumerable.added << post
            end

            it "returns the equality check" do
              enumerable.should eq([ post ])
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
        enumerable.should_not eq("person")
      end
    end
  end

  describe "#<<" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    let!(:post) do
      Post.create(:person_id => person.id)
    end

    let!(:enumerable) do
      described_class.new([])
    end

    let!(:added) do
      enumerable << post
    end

    it "adds the document to the added target" do
      enumerable.added.should eq([ post ])
    end

    it "returns the added documents" do
      added.should eq([ post ])
    end
  end

  describe "#clear" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    let!(:post) do
      Post.create(:person_id => person.id)
    end

    let!(:post_two) do
      Post.create(:person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
    end

    let(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable.loaded << post
      enumerable << post
    end

    let!(:clear) do
      enumerable.clear do |doc|
        doc.should be_a(Post)
      end
    end

    it "clears out the loaded docs" do
      enumerable.loaded.should be_empty
    end

    it "clears out the added docs" do
      enumerable.added.should be_empty
    end

    it "retains its loaded state" do
      enumerable.should_not be_loaded
    end
  end

  describe "#clone" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    let!(:post) do
      Post.create(:title => "one", :person_id => person.id)
    end

    let!(:post_two) do
      Post.create(:title => "two", :person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
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

    it "clones the first document in the enumerable" do
      cloned.first.title.should eq("one")
    end

    it "does not retain the first id" do
      cloned.first.should_not eq(post)
    end

    it "clones the last document in the enumerable" do
      cloned.last.title.should eq("two")
    end

    it "does not retain the last id" do
      cloned.last.should_not eq(post_two)
    end
  end

  describe "#delete" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    context "when the document is loaded" do

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete(post)
      end

      it "deletes the document from the enumerable" do
        enumerable.loaded.should be_empty
      end

      it "returns the document" do
        deleted.should eq(post)
      end
    end

    context "when the document is added" do

      let!(:post) do
        Post.new
      end

      let(:criteria) do
        Person.where(:person_id => person.id)
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
        enumerable.added.should be_empty
      end

      it "returns the document" do
        deleted.should eq(post)
      end
    end

    context "when the document is unloaded" do

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      let(:criteria) do
        Post.where(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let!(:deleted) do
        enumerable.delete(post)
      end

      it "does not load the document" do
        enumerable.loaded.should be_empty
      end

      it "returns the document" do
        deleted.should eq(post)
      end
    end

    context "when the document is not found" do

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      let(:criteria) do
        Person.where(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete(Post.new) do |doc|
          doc.should be_nil
        end
      end

      it "returns nil" do
        deleted.should be_nil
      end
    end
  end

  describe "#delete_if" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    context "when the document is loaded" do

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == post }
      end

      it "deletes the document from the enumerable" do
        enumerable.loaded.should be_empty
      end

      it "returns the remaining docs" do
        deleted.should eq([])
      end
    end

    context "when the document is added" do

      let!(:post) do
        Post.new
      end

      let(:criteria) do
        Person.where(:person_id => person.id)
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
        enumerable.added.should be_empty
      end

      it "returns the remaining docs" do
        deleted.should eq([])
      end
    end

    context "when the document is unloaded" do

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      let(:criteria) do
        Post.where(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == post }
      end

      it "does not load the document" do
        enumerable.loaded.should be_empty
      end

      it "returns the remaining docs" do
        deleted.should eq([])
      end
    end

    context "when the block doesn't match" do

      let!(:post) do
        Post.create(:person_id => person.id)
      end

      let(:criteria) do
        Person.where(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:deleted) do
        enumerable.delete_if { |doc| doc == Post.new }
      end

      it "returns the remaining docs" do
        deleted.should eq([ post ])
      end
    end
  end

  describe "#each" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    let!(:post) do
      Post.create(:person_id => person.id)
    end

    context "when only a criteria target exists" do

      let(:criteria) do
        Post.where(:person_id => person.id)
      end

      let!(:enumerable) do
        described_class.new(criteria)
      end

      let!(:iterated) do
        enumerable.each do |doc|
          doc.should be_a(Post)
        end
      end

      it "loads each document" do
        enumerable.loaded.should eq([ post ])
      end

      it "becomes loaded" do
        enumerable.should be_loaded
      end
    end

    context "when only an array target exists" do

      let!(:enumerable) do
        described_class.new([ post ])
      end

      let!(:iterated) do
        enumerable.each do |doc|
          doc.should be_a(Post)
        end
      end

      it "does not alter the loaded docs" do
        enumerable.loaded.should eq([ post ])
      end

      it "stays loaded" do
        enumerable.should be_loaded
      end
    end

    context "when a criteria and added exist" do

      let(:criteria) do
        Post.where(:person_id => person.id)
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
            doc.should be_a(Post)
          end
        end

        it "adds the unloaded to the loaded docs" do
          enumerable.loaded.should eq([ post ])
        end

        it "keeps the appended in the added docs" do
          enumerable.added.should eq([ post_two ])
        end

        it "stays loaded" do
          enumerable.should be_loaded
        end
      end

      context "when the added contains unloaded docs" do

        before do
          enumerable << post
        end

        let!(:iterated) do
          enumerable.each do |doc|
            doc.should be_a(Post)
          end
        end

        it "adds the persisted added doc to the loaded" do
          enumerable.loaded.should eq([ post ])
        end

        it "stays loaded" do
          enumerable.should be_loaded
        end
      end
    end
  end

  describe "#first" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    context "when the enumerable is not loaded" do

      let(:criteria) do
        Post.where(:person_id => person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      context "when unloaded is not empty" do

        context "when added is empty" do

          let!(:post) do
            Post.create(:person_id => person.id)
          end

          let(:first) do
            enumerable.first
          end

          it "returns the first unloaded doc" do
            first.should eq(post)
          end

          it "does not load the enumerable" do
            enumerable.should_not be_loaded
          end
        end

        context "when added is not empty" do

          let!(:post) do
            Post.create(:person_id => person.id)
          end

          let(:post_two) do
            Post.new(:person_id => person.id)
          end

          before do
            enumerable << post_two
          end

          let(:first) do
            enumerable.first
          end

          it "returns the first added doc" do
            first.should eq(post_two)
          end

          it "does not load the enumerable" do
            enumerable.should_not be_loaded
          end
        end
      end

      context "when unloaded is empty" do

        let!(:post) do
          Post.new(:person_id => person.id)
        end

        before do
          enumerable << post
        end

        let(:first) do
          enumerable.first
        end

        it "returns the first unloaded doc" do
          first.should eq(post)
        end

        it "does not load the enumerable" do
          enumerable.should_not be_loaded
        end
      end

      context "when unloaded and added are empty" do

        let(:first) do
          enumerable.first
        end

        it "returns nil" do
          first.should be_nil
        end

        it "does not load the enumerable" do
          enumerable.should_not be_loaded
        end
      end
    end

    context "when the enumerable is loaded" do

      context "when loaded is not empty" do

        let!(:post) do
          Post.create(:person_id => person.id)
        end

        let(:enumerable) do
          described_class.new([ post ])
        end

        let(:first) do
          enumerable.first
        end

        it "returns the first loaded doc" do
          first.should eq(post)
        end
      end

      context "when loaded is empty" do

        let!(:post) do
          Post.create(:person_id => person.id)
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
          first.should eq(post)
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
          first.should be_nil
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
        Post.where(:person_id => person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      it "sets the criteria" do
        enumerable.unloaded.should eq(criteria)
      end

      it "is not loaded" do
        enumerable.should_not be_loaded
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
        enumerable.unloaded.should be_nil
      end

      it "is loaded" do
        enumerable.should be_loaded
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
        in_memory.should eq([ post, post_two ])
      end
    end

    context "when the enumerable is not loaded" do

      let(:post) do
        Post.new(:person_id => person.id)
      end

      let(:enumerable) do
        described_class.new(Post.where(:person_id => person.id))
      end

      let(:post_two) do
        Post.new(:person_id => person.id)
      end

      before do
        enumerable << post_two
      end

      let(:in_memory) do
        enumerable.in_memory
      end

      it "returns the added docs" do
        in_memory.should eq([ post_two ])
      end
    end

    context "when passed a block" do

      let(:enumerable) do
        described_class.new(Post.where(:person_id => person.id))
      end

      let(:post_two) do
        Post.new(:person_id => person.id)
      end

      before do
        enumerable << post_two
      end

      it "yields to each in memory document" do
        enumerable.in_memory do |doc|
          doc.should eq(post_two)
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
        enumerable.is_a?(::Enumerable).should be_true
      end
    end

    context "when checking against array" do

      it "returns true" do
        enumerable.is_a?(Array).should be_true
      end
    end
  end

  describe "#last" do

    let(:person) do
      Person.create(:ssn => "543-98-1234")
    end

    context "when the enumerable is not loaded" do

      let(:criteria) do
        Post.where(:person_id => person.id)
      end

      let(:enumerable) do
        described_class.new(criteria)
      end

      context "when unloaded is not empty" do

        let!(:post) do
          Post.create(:person_id => person.id)
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last unloaded doc" do
          last.should eq(post)
        end

        it "does not load the enumerable" do
          enumerable.should_not be_loaded
        end
      end

      context "when unloaded is empty" do

        let!(:post) do
          Post.new(:person_id => person.id)
        end

        before do
          enumerable << post
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last unloaded doc" do
          last.should eq(post)
        end

        it "does not load the enumerable" do
          enumerable.should_not be_loaded
        end
      end

      context "when unloaded and added are empty" do

        let(:last) do
          enumerable.last
        end

        it "returns nil" do
          last.should be_nil
        end

        it "does not load the enumerable" do
          enumerable.should_not be_loaded
        end
      end
    end

    context "when the enumerable is loaded" do

      context "when loaded is not empty" do

        let!(:post) do
          Post.create(:person_id => person.id)
        end

        let(:enumerable) do
          described_class.new([ post ])
        end

        let(:last) do
          enumerable.last
        end

        it "returns the last loaded doc" do
          last.should eq(post)
        end
      end

      context "when loaded is empty" do

        let!(:post) do
          Post.create(:person_id => person.id)
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
          last.should eq(post)
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
          last.should be_nil
        end
      end
    end
  end

  describe "#kind_of?" do

    let(:enumerable) do
      described_class.new(Post.all)
    end

    context "when checking against enumerable" do

      it "returns true" do
        enumerable.kind_of?(::Enumerable).should be_true
      end
    end

    context "when checking against array" do

      it "returns true" do
        enumerable.kind_of?(Array).should be_true
      end
    end
  end

  describe "#load_all!" do

    let(:person) do
      Person.create(:ssn => "422-21-9687")
    end

    let!(:post) do
      Post.create(:person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    let!(:loaded) do
      enumerable.load_all!
    end

    it "loads all the unloaded documents" do
      enumerable.loaded.should eq([ post ])
    end

    it "returns true" do
      loaded.should be_true
    end

    it "sets loaded to true" do
      enumerable.should be_loaded
    end
  end

  describe "#reset" do

    let(:person) do
      Person.create(:ssn => "543-98-1238")
    end

    let(:post) do
      Post.create(:person_id => person.id)
    end

    let(:post_two) do
      Post.create(:person_id => person.id)
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
      enumerable.should_not be_loaded
    end

    it "clears out the loaded docs" do
      enumerable.loaded.should be_empty
    end

    it "clears out the added docs" do
      enumerable.added.should be_empty
    end
  end

  describe "#respond_to?" do

    let(:enumerable) do
      described_class.new([])
    end

    context "when checking against array methods" do

      [].methods.each do |method|

        it "returns true for #{method}" do
          enumerable.should respond_to(method)
        end
      end
    end
  end

  describe "#size" do

    let(:person) do
      Person.create(:ssn => "543-98-1238")
    end

    let!(:post) do
      Post.create(:person_id => person.id)
    end

    context "when the enumerable is loaded" do

      let(:enumerable) do
        described_class.new([ post ])
      end

      let(:post_two) do
        Post.new(:person_id => person.id)
      end

      before do
        enumerable << post_two
      end

      let(:size) do
        enumerable.size
      end

      it "returns the loaded size plus added size" do
        size.should eq(2)
      end
    end

    context "when the enumerable is not loaded" do

      let(:enumerable) do
        described_class.new(Post.where(:person_id => person.id))
      end

      context "when the added contains new documents" do

        let(:post_two) do
          Post.new(:person_id => person.id)
        end

        before do
          enumerable << post_two
        end

        let(:size) do
          enumerable.size
        end

        it "returns the unloaded count plus added new size" do
          size.should eq(2)
        end
      end

      context "when the added contains persisted documents" do

        let(:post_two) do
          Post.create(:person_id => person.id)
        end

        before do
          enumerable << post_two
        end

        let(:size) do
          enumerable.size
        end

        it "returns the unloaded count plus added new size" do
          size.should eq(2)
        end
      end
    end
  end

  describe "#to_json" do

    let(:person) do
      Person.create(:ssn => "422-21-9687")
    end

    let!(:post) do
      Post.create(:title => "test", :person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
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
      json.should include(post.title)
    end
  end

  describe "#to_json(parameters)" do

    let(:person) do
      Person.create(:ssn => "422-21-9687")
    end

    let!(:post) do
      Post.create(:title => "test", :person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
    end

    let!(:json) do
      person.posts.to_json({:except => 'title'})
    end

    it "serializes the enumerable" do
      json.should_not include(post.title)
    end
  end

  describe "#as_json" do

    let(:person) do
      Person.create(:ssn => "422-21-9687")
    end

    let!(:post) do
      Post.create(:title => "test", :person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
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
      json.size.should == 1
      json[0]['title'].should == post.title
    end
  end

  describe "#as_json(parameters)" do

    let(:person) do
      Person.create(:ssn => "422-21-9687")
    end

    let!(:post) do
      Post.create(:title => "test", :person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
    end

    let!(:json) do
      person.posts.as_json({:except => 'title'})
    end

    it "serializes the enumerable" do
      json.size.should == 1
      json[0].keys.should_not include('title')
    end
  end

  describe "#uniq" do

    let(:person) do
      Person.create(:ssn => "422-21-9687")
    end

    let!(:post) do
      Post.create(:person_id => person.id)
    end

    let(:criteria) do
      Post.where(:person_id => person.id)
    end

    let!(:enumerable) do
      described_class.new(criteria)
    end

    before do
      enumerable << post
      enumerable.loaded << post
    end

    let!(:uniq) do
      enumerable.uniq
    end

    it "returns the unique documents" do
      uniq.should eq([ post ])
    end

    it "sets loaded to true" do
      enumerable.should be_loaded
    end
  end
end
