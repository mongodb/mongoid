require "spec_helper"

describe Mongoid::NamedScope do

  before do
    [ Person, Player ].each(&:delete_all)
  end

  describe ".scope" do

    before(:all) do
      Person.class_eval do
        scope :doctors, {:where => {:title => 'Dr.'} }
        scope :old, criteria.where(:age.gt => 50)
        scope :alki, where(:blood_alcohol_content.gt => 0.3).order_by(:blood_alcohol_content.asc)
      end
    end

    let!(:document) do
      Person.create(
        :title => "Dr.",
        :age => 65,
        :terms => true,
        :ssn => "123-22-8346"
      )
    end

    after do
      Person.delete_all
    end

    it "adds a class method for the scope" do
      Player.should respond_to(:active)
    end

    it "adds the scope to the scopes" do
      Player.scopes.should include(:active)
    end

    it "aliases to named_scope" do
      Player.should respond_to(:deaths_over)
    end

    context "when accessing an any_of scope first" do

      let(:criteria) do
        Person.search("Dr.").old
      end

      it "returns the correct results" do
        criteria.should eq([ document ])
      end
    end

    context "accessing a single named scope" do

      it "returns the document" do
        Person.doctors.first.should eq(document)
      end
    end

    context "chaining named scopes" do

      it "returns the document" do
        Person.old.doctors.first.should eq(document)
      end
    end

    context "mixing named scopes and class methods" do

      it "returns the document" do
        Person.accepted.old.doctors.first.should eq(document)
      end
    end

    context "using order_by in a named scope" do

      before do
        Person.create(:blood_alcohol_content => 0.5, :ssn => "121-22-8346")
        Person.create(:blood_alcohol_content => 0.4, :ssn => "124-22-8346")
        Person.create(:blood_alcohol_content => 0.7, :ssn => "125-22-8346")
      end

      it "sorts the results" do
        docs = Person.alki
        docs.first.blood_alcohol_content.should eq(0.4)
      end
    end

    context "when an class attribute is defined" do

      it "bes accessible" do
        Person.somebody_elses_important_class_options.should eq({ :keep_me_around => true })
      end

    end

    context "when calling scopes on parent classes" do

      it "inherits the scope" do
        Doctor.minor.should be_empty
      end

      it "inherits the class attribute methods" do
        Doctor.somebody_elses_important_class_options.should eq({ :keep_me_around => true })
      end
    end

    context "when overwriting an existing scope" do

      it "logs warnings per default" do
        require 'stringio'
        log_io = StringIO.new
        Mongoid.logger = ::Logger.new(log_io)
        Mongoid.scope_overwrite_exception = false

        Person.class_eval do
          scope :old, criteria.where(:age.gt => 67)
        end

        log_io.rewind
        log_io.readlines.join.should =~
          /Creating scope :old. Overwriting existing method Person.old/
      end

      it "throws exception if configured with scope_overwrite_exception = true" do
        Mongoid.scope_overwrite_exception = true
        lambda {
          Person.class_eval do
            scope :old, criteria.where(:age.gt => 67)
          end
        }.should raise_error(
          Mongoid::Errors::ScopeOverwrite,
          "Cannot create scope :old, because of existing method Person.old."
        )
      end
    end

    context "when options are a hash" do

      it "adds the selector to the scope" do
        Player.inactive.selector[:active].should be_false
      end
    end

    context "when options are a criteria" do

      it "adds the selector to the scope" do
        Player.active.selector[:active].should be_true
      end
    end

    context "when options are a proc" do

      context "when the proc delegates to a hash" do

        it "adds the selector to the scope" do
          Player.frags_over(50).selector[:frags].should eq({ "$gt" => 50 })
        end
      end

      context "when the proc delegates to a criteria" do

        it "adds the selector to the scope" do
          Player.deaths_under(40).selector[:deaths].should eq({ "$lt" => 40 })
        end
      end
    end

    context "when a block is supplied" do

      it "adds a class method for the scope" do
        Player.should respond_to(:deaths_over)
      end

      it "adds the scope to the scopes" do
        Player.scopes.should include(:deaths_over)
      end
    end

    context "when overrides a class method" do

      context "when raising an error on override" do

        it "raises an error on public method" do
          expect {
            Override.scope :public_method
          }.to raise_error(Mongoid::Errors::ScopeOverwrite)
        end

        it "raises an error on protected method" do
          expect {
            Override.scope :protected_method
          }.to raise_error(Mongoid::Errors::ScopeOverwrite)
        end

        it "raises an error on private method" do
          expect {
            Override.scope :private_method
          }.to raise_error(Mongoid::Errors::ScopeOverwrite)
        end
      end
    end
  end

  describe ".scoped" do

    context "when a default scope is provided" do

      let(:criteria) do
        Acolyte.scoped
      end

      it "returns a criteria with default scoping options" do
        criteria.options.should eq({ :sort => [[ :name, :asc ]] })
      end
    end

    context "when no default scope is provided" do

      let(:criteria) do
        Person.scoped
      end

      it "returns a criteria with no default scoping" do
        criteria.selector.should eq({})
      end

      it "returns a criteria with no default options" do
        criteria.options.should eq({})
      end
    end
  end

  describe ".scope_stack" do

    context "when a scope is on the stack" do

      let(:criteria) do
        Mongoid::Criteria.new(Person, false)
      end

      before do
        Person.scope_stack << criteria
      end

      after do
        Person.scope_stack.clear
      end

      it "returns the scope stack for the class" do
        Person.scope_stack.should eq([ criteria ])
      end
    end

    context "when no scope is on the stack" do

      it "returns an empty array" do
        Person.scope_stack.should be_empty
      end
    end
  end

  describe ".unscoped" do

    let(:criteria) do
      Acolyte.unscoped
    end

    it "returns a criteria with no selector" do
      criteria.selector.should eq({})
    end

    it "returns a criteria with no options" do
      criteria.options.should eq({})
    end
  end

  context "when chaining scopes" do

    context "when chaining two named scopes" do

      let(:selector) do
        Player.active.frags_over(10).selector
      end

      it "retains the first criteria" do
        selector[:active].should be_true
      end

      it "retains the second criteria" do
        selector[:frags].should eq({ "$gt" => 10 })
      end

      context "when both scoped have in clauses" do

        let!(:chained) do
          Event.best.by_kind("party")
        end

        let(:initial) do
          Event.best
        end

        it "does not modify the initial scope" do
          initial.selector.should eq(
            { :kind => { "$in" => [ "party", "concert" ]}}
          )
        end
      end
    end

    context "when chaining named scoped with criteria class methods" do

      let(:selector) do
        Player.active.frags_over(10).alive.selector
      end

      it "retains the first criteria" do
        selector[:active].should be_true
      end

      it "retains the second criteria" do
        selector[:frags].should eq({ "$gt" => 10 })
      end

      it "retains the class method criteria" do
        selector[:status].should eq("Alive")
      end
    end
  end
end
