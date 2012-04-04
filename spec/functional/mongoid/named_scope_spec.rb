require "spec_helper"

describe Mongoid::NamedScope do

  describe ".scope" do

    before(:all) do
      Person.class_eval do
        scope :doctors, {:where => {:title => 'Dr.'} }
        scope :old, criteria.where(:age.gt => 50)
        scope :alki, where(:blood_alcohol_content.gt => 0.3).order_by(:blood_alcohol_content.asc)

        scope :by_ids, lambda { |ids| where(:_id.in => ids) }
        scope :limited, lambda { only(:_id, :title) }
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

    context "when accessing an any_of scope first" do

      let(:criteria) do
        Person.search("Dr.").old
      end

      it "returns the correct results" do
        criteria.should eq([ document ])
      end
    end

    context "when accessing a single named scope" do

      it "returns the document" do
        Person.doctors.first.should eq(document)
      end
    end

    context "when chaining named scopes" do

      it "returns the document" do
        Person.old.doctors.first.should eq(document)
      end

      context "when the named scopes are lambdas" do

        context "when a scope has id criterion" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:scoped) do
            Person.by_ids([ id ]).limited
          end

          it "does not double merge the id criterion" do
            scoped.selector.should eq({ :_id => { "$in" => [ id ] }})
          end
        end
      end
    end

    context "mixing named scopes and class methods" do

      it "returns the document" do
        Person.accepted.old.doctors.first.should == document
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
        docs.first.blood_alcohol_content.should == 0.4
      end
    end

    context "when an class attribute is defined" do

      it "should be accessible" do
        Person.somebody_elses_important_class_options.should == { :keep_me_around => true }
      end

    end

    context "when calling scopes on parent classes" do

      it "inherits the scope" do
        Doctor.minor.should == []
      end

      it "inherits the class attribute methods" do
        Doctor.somebody_elses_important_class_options.should == { :keep_me_around => true }
      end

    end

    context "when there is a scope on parent class" do

      before do
        Person.class_eval do
          scope(:important, where(:title => 'VIP'))
        end
      end

      context "when overwriting scope in child class" do

        before do
          Doctor.class_eval do
            scope(:important, where(:title => 'Dr.' ))
          end
        end

        it "changes the child's scope" do
          Doctor.important.selector.should eq({ :title => 'Dr.' })
        end

        it "leaves the scope on parent class unchanged" do
          Person.important.selector.should eq({ :title => 'VIP' })
        end
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

  end
end
