# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Depending do

  describe '.included' do

    context 'when a destroy dependent is defined' do

      context 'when the model is a subclass' do

        context 'when transitive dependents are defined' do

          let(:define_classes) do
            class DependentReportCard
              include Mongoid::Document

              belongs_to :dependent_student
            end

            class DependentUser
              include Mongoid::Document
            end

            class DependentStudent < DependentUser
              belongs_to :dependent_teacher
              has_many :dependent_report_cards, dependent: :destroy
            end

            class DependentDerivedStudent < DependentStudent; end

            class DependentTeacher
              include Mongoid::Document

              has_many :dependent_students, dependent: :destroy
            end

            class DependentCollegeUser < DependentUser; end
          end

          it "does not add the dependent to superclass" do
            define_classes

            expect(DependentUser.dependents).to be_empty

            u = DependentUser.create!
            expect(u.dependents).to be_empty
          end

          it 'does not impede destroying the superclass' do
            define_classes

            u = DependentUser.create!
            expect { u.destroy! }.not_to raise_error
          end

          it 'adds the dependent' do
            define_classes

            expect(DependentStudent.dependents.length).to be(1)
            expect(DependentStudent.dependents.first.name).to be(:dependent_report_cards)

            s = DependentStudent.create!
            expect(s.dependents.length).to be(1)
            expect(s.dependents.first.name).to be(:dependent_report_cards)
          end

          it 'facilitates proper destroying of the object' do
            define_classes

            s = DependentStudent.create!
            r = DependentReportCard.create!(dependent_student: s)
            s.destroy!

            expect { DependentReportCard.find(r.id) }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class DependentReportCard with id\(s\)/)
          end

          it 'facilitates proper transitive destroying of the object' do
            define_classes

            t = DependentTeacher.create!
            s = DependentStudent.create!(dependent_teacher: t)
            r = DependentReportCard.create!(dependent_student: s)
            s.destroy!

            expect { DependentReportCard.find(r.id) }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class DependentReportCard with id\(s\)/)
          end

          it 'adds the dependent to subclasses' do
            define_classes

            expect(DependentDerivedStudent.dependents.length).to be(1)
            expect(DependentDerivedStudent.dependents.first.name).to be(:dependent_report_cards)

            s = DependentDerivedStudent.create!
            expect(s.dependents.length).to be(1)
            expect(s.dependents.first.name).to be(:dependent_report_cards)
          end

          it 'facilitates proper destroying of the object from subclasses' do
            define_classes

            s = DependentDerivedStudent.create!
            r = DependentReportCard.create!(dependent_student: s)
            s.destroy!

            expect { DependentReportCard.find(r.id) }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class DependentReportCard with id\(s\)/)
          end

          it "doesn't add the dependent to sibling classes" do
            define_classes

            expect(DependentCollegeUser.dependents).to be_empty

            c = DependentCollegeUser.create!
            expect(c.dependents).to be_empty
          end

          it 'does not impede destroying the sibling class' do
            define_classes

            c = DependentCollegeUser.create!
            expect { c.destroy! }.not_to raise_error
          end
        end

        context 'when a superclass is reopened and a new dependent is added' do
          let(:define_classes) do
            class DependentOwnedOne
              include Mongoid::Document

              belongs_to :dependent_superclass
            end

            class DependentOwnedTwo
              include Mongoid::Document

              belongs_to :dependent_superclass
            end

            class DependentSuperclass
              include Mongoid::Document
              has_one :dependent_owned_one
              has_one :dependent_owned_two
            end

            class DependentSubclass < DependentSuperclass
              has_one :dependent_owned_two, dependent: :nullify
            end

            class DependentSuperclass
              has_one :dependent_owned_one, dependent: :destroy
            end
          end

          it 'defines the dependent from the reopened superclass on the subclass' do
            define_classes

            DependentSubclass.create!.destroy!

            expect(DependentSubclass.dependents.length).to be(1)
            expect(DependentSubclass.dependents.last.name).to be(:dependent_owned_two)
            expect(DependentSubclass.dependents.last.options[:dependent]).to be(:nullify)

            subclass = DependentSubclass.create!
            expect(subclass.dependents.last.name).to be(:dependent_owned_two)
            expect(subclass.dependents.last.options[:dependent]).to be(:nullify)
          end

          it 'causes the destruction of the inherited destroy dependent' do
            define_classes

            subclass = DependentSubclass.create!
            owned = DependentOwnedOne.create!(dependent_superclass: subclass)
            subclass.destroy!

            expect {
              DependentOwnedOne.find(owned.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class DependentOwnedOne with id\(s\)/)
          end
        end

        context 'when a separate subclass overrides the destroy dependent' do
          let(:define_classes) do
            class Dep
              include Mongoid::Document

              belongs_to :double_assoc
            end

            class DoubleAssoc
              include Mongoid::Document

              has_many :deps, dependent: :destroy
            end

            class DoubleAssocOne < DoubleAssoc
              has_many :deps, dependent: :nullify, inverse_of: :double_assoc
            end

            class DoubleAssocTwo < DoubleAssocOne
              has_many :deps, dependent: :destroy, inverse_of: :double_assoc
            end

            class DoubleAssocThree < DoubleAssoc; end
          end

          it 'adds the non-destroy dependent correctly to the subclass with the override' do
            define_classes

            expect(DoubleAssocOne.dependents.length).to be(1)
            expect(DoubleAssocOne.dependents.first.name).to be(:deps)
            expect(DoubleAssocOne.dependents.first.options[:dependent]).to be(:nullify)

            one = DoubleAssocOne.create!
            expect(one.dependents.length).to be(1)
            expect(one.dependents.first.name).to be(:deps)
            expect(one.dependents.first.options[:dependent]).to be(:nullify)
          end

          it 'does not cause the destruction of the non-destroy dependent' do
            define_classes

            one = DoubleAssocOne.create!
            dep = Dep.create!(double_assoc: one)
            one.destroy!

            expect { Dep.find(dep.id) }.not_to raise_error
            expect(dep.double_assoc).to be_nil
          end

          it 'adds the destroy dependent correctly to the subclass without the override' do
            define_classes

            expect(DoubleAssocTwo.dependents.length).to be(1)
            expect(DoubleAssocTwo.dependents.first.name).to be(:deps)
            expect(DoubleAssocTwo.dependents.first.options[:dependent]).to be(:destroy)

            two = DoubleAssocTwo.create!
            expect(two.dependents.length).to be(1)
            expect(two.dependents.first.name).to be(:deps)
            expect(two.dependents.first.options[:dependent]).to be(:destroy)
          end

          it 'causes the destruction of the destroy dependent' do
            define_classes

            two = DoubleAssocTwo.create!
            dep = Dep.create!(double_assoc: two)
            two.destroy!

            expect { Dep.find(dep.id) }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Dep with id\(s\)/)
          end
        end
      end
    end
  end

  around(:each) do |example|
    relations_before = Person.relations
    example.run
    Person.relations = relations_before
  end

  describe "#apply_destroy_dependencies!" do

    let(:band) do
      Band.new
    end

    context "when the association exists in the list of dependencies" do

      context "when the association has no dependent strategy" do

        before do
          band.dependents.push(Band.relations["records"])
        end

        after do
          band.dependents.delete(Band.relations["records"])
        end

        it "ignores the dependency" do
          expect(band.apply_destroy_dependencies!).to eq([Band.relations["records"]])
        end
      end
    end
  end

  describe ".define_dependency!" do

    let(:klass) do
      Class.new.tap { |c| c.send(:include, Mongoid::Document) }
    end

    context "when the association metadata doesnt exist" do

      before do
        klass.dependents.push("nothing")
      end

      it "does not raise an error" do
        expect {
          klass.new.apply_destroy_dependencies!
        }.not_to raise_error
      end
    end

    context "when a dependent option is provided" do

      let!(:association) do
        klass.has_many :posts, dependent: :destroy
      end

      after do
        klass.relations.delete(association.name.to_s)
      end

      it "adds the relation to the dependents" do
        expect(klass.dependents).to include(klass.relations["posts"])
      end
    end

    context "when no dependent option is provided" do

      let!(:association) do
        klass.has_many :posts
      end

      after do
        klass.relations.delete(association.name.to_s)
      end

      it "does not add a relation to the dependents" do
        expect(klass.dependents).to_not include(association)
      end
    end

    context 'when the class is defined more than once' do

      let!(:association) do
        klass.has_many :posts, dependent: :destroy
        klass.has_many :posts, dependent: :destroy
      end

      it 'only creates the dependency once' do
        expect(klass.dependents.size).to eq(1)
      end
    end
  end

  describe '#delete and #destroy' do
    context "when cascading removals" do

      shared_examples 'destroys dependents if parent is destroyed but does not if parent is deleted' do
        context '#destroy' do
          before do
            parent.destroy
          end

          it "deletes the associated documents" do
            expect {
              child.class.find(child.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class #{child.class.to_s} with id\(s\)/)
          end
        end

        context '#delete' do
          before do
            parent.delete
          end

          it "does not delete the associated documents" do
            child.class.find(child.id).should == child
          end
        end
      end

      context "when strategy is delete" do

        let(:parent) do
          Person.create!
        end

        let!(:child) do
          parent.posts.create!(title: "Testing")
        end

        include_examples 'destroys dependents if parent is destroyed but does not if parent is deleted'
      end

      context "when strategy is destroy" do

        let(:parent) do
          Person.create!
        end

        let!(:child) do
          parent.create_game(name: "Pong")
        end

        include_examples 'destroys dependents if parent is destroyed but does not if parent is deleted'
      end

      context "when strategy is nullify" do

        shared_examples 'removes references if parent is destroyed but does not if parent is deleted' do
          context '#destroy' do
            before do
              parent.destroy
            end

            it "removes the references to the removed document" do
              expect(from_db.ratable_id).to be_nil
            end
          end

          context '#delete' do
            before do
              parent.delete
            end

            it "does not remove the references to the removed document" do
              from_db.ratable_id.should == parent.id
            end
          end
        end

        context "when nullifying a references many" do

          let(:parent) do
            Movie.create!(title: "Bladerunner")
          end

          let!(:rating) do
            parent.ratings.create!(value: 10)
          end

          let(:from_db) do
            Rating.find(rating.id)
          end

          include_examples 'removes references if parent is destroyed but does not if parent is deleted'
        end

        context "when nullifying a references one" do

          context "when the relation exists" do

            let(:parent) do
              Book.create!(title: "Neuromancer")
            end

            let!(:rating) do
              parent.create_rating(value: 10)
            end

            let(:from_db) do
              Rating.find(rating.id)
            end

            include_examples 'removes references if parent is destroyed but does not if parent is deleted'
          end

          context "when no association target exists" do

            let(:parent) do
              Book.create!(title: "Neuromancer")
            end

            [:delete, :destroy].each do |method|

              describe "##{method}" do
                it "succeeds" do
                  expect(parent.send(method)).to be true
                end
              end
            end
          end
        end

        context "when nullifying a many to many" do

          let(:person) do
            Person.create!
          end

          let!(:preference) do
            person.preferences.create!(name: "Setting")
          end

          let(:from_db) do
            Preference.find(preference.id)
          end

          context '#destroy' do
            before do
              person.destroy
            end

            it "removes the references from the removed document" do
              expect(person.preference_ids).to_not include(preference.id)
            end

            it "removes the references to the removed document" do
              expect(from_db.person_ids).to_not include(person.id)
            end
          end

          context '#delete' do
            before do
              person.delete
            end

            it "keeps the references from the removed document" do
              expect(person.preference_ids).to include(preference.id)
            end

            it "keeps the references to the removed document" do
              expect(from_db.person_ids).to include(person.id)
            end
          end
        end
      end

      shared_examples 'deletes the parent with #delete and #destroy' do
        [:delete, :destroy].each do |method|

          describe "##{method}" do
            it "raises no error" do
              expect { person.send(method) }.to_not raise_error
            end

            it "deletes the parent" do
              person.send(method)
              expect(person).to be_destroyed
            end
          end
        end
      end

      shared_examples 'raises an error with #destroy and deletes the parent with #delete' do
        context '#destroy' do
          it "raises DeleteRestriction error" do
            expect { person.destroy }.to raise_error(Mongoid::Errors::DeleteRestriction)
          end
        end

        context '#delete' do
          it "deletes the parent" do
            person.delete
            expect(person).to be_destroyed
          end
        end
      end

      context "when dependent is restrict_with_exception" do

        context "when restricting a references many" do

          let!(:association) do
            Person.has_many :drugs, dependent: :restrict_with_exception
          end

          after do
            Person.dependents.delete(association)
            Person.has_many :drugs, validate: false
          end

          context "when the relation is empty" do

            let(:person) do
              Person.new drugs: []
            end

            include_examples 'deletes the parent with #delete and #destroy'
          end

          context "when the relation is not empty" do

            let(:person) do
              Person.new drugs: [Drug.new]
            end

            include_examples 'raises an error with #destroy and deletes the parent with #delete'
          end
        end

        context "when restricting a references one" do

          let!(:association) do
            Person.has_one :account, dependent: :restrict_with_exception
          end

          after do
            Person.dependents.delete(association)
            Person.has_one :account, validate: false
          end

          context "when the relation is empty" do

            let(:person) do
              Person.new account: nil
            end

            include_examples 'deletes the parent with #delete and #destroy'
          end

          context "when the relation is not empty" do

            let(:person) do
              Person.new account: Account.new(name: 'test')
            end

            include_examples 'raises an error with #destroy and deletes the parent with #delete'
          end
        end

        context "when restricting a many to many" do

          let!(:association) do
            Person.has_and_belongs_to_many :houses, dependent: :restrict_with_exception
          end

          after do
            Person.dependents.delete(association)
            Person.has_and_belongs_to_many :houses, validate: false
          end

          context "when the relation is empty" do

            let(:person) do
              Person.new houses: []
            end

            include_examples 'deletes the parent with #delete and #destroy'
          end

          context "when the relation is not empty" do

            let(:person) do
              Person.new houses: [House.new]
            end

            include_examples 'raises an error with #destroy and deletes the parent with #delete'
          end
        end
      end
    end

    context 'when the strategy is :delete_all' do

      let(:person) do
        Person.create!
      end

      context "when cascading a has one" do

        context "when the relation exists" do

          let!(:home) do
            person.create_home
          end

          before do
            person.destroy
          end

          it "deletes the dependents" do
            expect(home).to be_destroyed
          end

          it "persists the deletion" do
            expect {
              home.reload
            }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Home with id\(s\)/)
          end
        end

        context "when the association target does not exist" do

          before do
            person.destroy
          end

          it "deletes the base document" do
            expect(person).to be_destroyed
          end
        end
      end

      context "when cascading a has many" do

        context "when the relation has documents" do

          let!(:post_one) do
            person.posts.create!(title: "one")
          end

          let!(:post_two) do
            person.posts.create!(title: "two")
          end

          context "when the documents are in memory" do

            before do
              expect(post_one).to receive(:delete).never
              expect(post_two).to receive(:delete).never
              person.destroy
            end

            it "deletes the first document" do
              expect(post_one).to be_destroyed
            end

            it "deletes the second document" do
              expect(post_two).to be_destroyed
            end

            it "unbinds the first document" do
              expect(post_one.person).to be_nil
            end

            it "unbinds the second document" do
              expect(post_two.person).to be_nil
            end

            it "removes the documents from the relation" do
              expect(person.posts).to be_empty
            end

            it "persists the first deletion" do
              expect {
                post_one.reload
              }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Post with id\(s\)/)
            end

            it "persists the second deletion" do
              expect {
                post_two.reload
              }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Post with id\(s\)/)
            end
          end
        end
      end
    end

    context 'when the strategy is :destroy' do

      let!(:association) do
        Person.has_many :destroyable_posts, class_name: "Post", dependent: :destroy
      end

      after do
        Person.dependents.delete(association)
      end

      let(:person) do
        Person.new
      end

      let(:post) do
        Post.new
      end

      context "when the documents exist" do

        before do
          expect(post).to receive(:destroy)
          person.destroyable_posts << post
        end

        it "destroys all documents in the association" do
          person.destroy
        end
      end

      context "when no documents exist" do

        before do
          expect(post).to receive(:destroy).never
        end

        it "it does not destroy the association target" do
          person.destroy
        end
      end
    end

    context 'when the strategy is :nullify' do

      let!(:association) do
        Person.has_many :nullifyable_posts, class_name: "Post", dependent: :nullify
      end

      after do
        Person.dependents.delete(association)
      end

      let(:person) do
        Person.new
      end

      let(:posts_relation) do
        person.posts
      end

      before do
        allow(person).to receive(:nullifyable_posts).and_return(posts_relation)
        expect(posts_relation).to receive(:nullify)
      end

      it "nullifies the association target" do
        person.destroy
      end
    end

    context 'when the strategy is :restrict_with_exception' do

      let(:person) do
        Person.new
      end

      let(:post) do
        Post.new
      end

      let!(:association) do
        Person.has_many :restrictable_posts, class_name: "Post", dependent: :restrict_with_exception
      end

      after do
        Person.dependents.delete(association)
      end

      context 'when there are related objects' do

        before do
          person.restrictable_posts << post
          expect(post).to receive(:delete).never
          expect(post).to receive(:destroy).never
        end

        it 'raises an exception and leaves the related one intact' do
          expect { person.destroy }.to raise_exception(Mongoid::Errors::DeleteRestriction)
        end
      end

      context 'when there are no related objects' do

        before do
          expect(post).to receive(:delete).never
          expect(post).to receive(:destroy).never
        end

        it 'deletes the object and leaves the other one intact' do
          expect(person.destroy).to be(true)
        end
      end
    end

    context 'when the strategy is :restrict_with_error' do

      context "when restricting a one-to-many" do

        let(:person) do
          Person.new
        end

        let(:post) do
          Post.new
        end

        let!(:association) do
          Person.has_many :restrictable_posts, class_name: "Post", dependent: :restrict_with_error
        end

        after do
          Person.dependents.delete(association)
        end

        context 'when there are related objects' do

          before do
            person.restrictable_posts << post
          end

          it 'adds an error to the parent object' do
            expect(person.destroy).to be(false)

            person.errors[:restrictable_posts].first.should ==
              "is not empty and prevents the document from being destroyed"
          end
        end

        context 'when there are no related objects' do

          before do
            expect(post).to receive(:delete).never
            expect(post).to receive(:destroy).never
          end

          it 'deletes the object and leaves the other one intact' do
            expect(person.destroy).to be(true)
          end
        end

        context 'when deleted inside a transaction' do
          require_transaction_support

          before do
            person.restrictable_posts << post
          end

          it 'doesn\'t raise an exception' do
            person.with_session do |session|
              session.with_transaction do
                expect { person.destroy }.to_not raise_error
              end
            end
          end
        end
      end

      context "when restricting a many to many" do

        let!(:association) do
          Person.has_and_belongs_to_many :houses, dependent: :restrict_with_error
        end

        after do
          Person.dependents.delete(association)
          Person.has_and_belongs_to_many :houses, validate: false
        end

        let(:person) do
          Person.new houses: [House.new]
        end

        it "returns false" do
          expect(person.destroy).to be false
        end

        context "when inside a transaction" do
          require_transaction_support

          it 'doesn\'t raise an exception inside a transaction' do
            person.with_session do |session|
              session.with_transaction do
                expect { person.destroy }.to_not raise_error
              end
            end
          end
        end
      end
    end
  end
end
