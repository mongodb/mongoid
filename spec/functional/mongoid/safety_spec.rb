require "spec_helper"

describe Mongoid::Safety do

  before(:all) do
    Mongoid.autocreate_indexes = true
  end

  before do
    Person.delete_all
  end

  after do
    Mongoid.autocreate_indexes = false
  end

  describe ".safely" do

    context "when global safe mode is false" do

      before do
        Mongoid.persist_in_safe_mode = false
      end

      describe ".create" do

        before do
          Person.safely.create(:ssn => "432-97-1111")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should == 1
          end
        end

        context "when a mongodb error occurs" do

          it "bubbles up to the caller" do
            lambda {
              Person.safely.create(:ssn => "432-97-1111")
            }.should raise_error(Mongo::OperationFailure)
          end
        end

        context "when using .safely(false)" do

          it "should ignore mongodb error" do
            Person.safely(false).create(:ssn => "432-97-1111").should be_true
          end

        end
      end

      describe ".create!" do

        before do
          Person.safely.create!(:ssn => "432-97-1112")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should == 1
          end
        end

        context "when a mongodb error occurs" do

          it "bubbles up to the caller" do
            lambda {
              Person.safely.create!(:ssn => "432-97-1112")
            }.should raise_error(Mongo::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          it "raises the validation error" do
            expect {
              Account.safely.create!(:name => "this name is way too long")
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end

      describe ".save" do

        before do
          Person.safely.create(:ssn => "432-97-1113")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(:ssn => "432-97-1113")
          end

          it "bubbles up to the caller" do
            lambda {
              person.safely.save(:ssn => "432-97-1113")
            }.should raise_error(Mongo::OperationFailure)
          end
        end
      end

      describe ".save!" do

        before do
          Person.safely.create!(:ssn => "432-97-1114")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(:ssn => "432-97-1114")
          end

          it "bubbles up to the caller" do
            lambda {
              person.safely.save!(:ssn => "432-97-1113")
            }.should raise_error(Mongo::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          let(:account) do
            Account.new(:name => "this name is way too long")
          end

          it "raises the validation error" do
            expect {
              account.safely.save!
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end

  end


  describe ".unsafely" do

    context "when global safe mode is true" do

        before do
          Mongoid.persist_in_safe_mode = true
        end

        after do
          Mongoid.persist_in_safe_mode = false
        end

        describe ".create" do

          before do
            Person.safely.create(:ssn => "432-97-1111")
          end

          context "when no error occurs" do

            it "inserts the document" do
              Person.count.should == 1
            end
          end

          context "when a mongodb error occurs" do

            it "should fail silently" do
              Person.unsafely.create(:ssn => "432-97-1111").should be_true
            end

            it "should still use defaults for subsequent requests" do
              Person.unsafely.create(:ssn => "432-97-1111")
              lambda {
                Person.create(:ssn => "432-97-1111")
              }.should raise_error(Mongo::OperationFailure)
            end
          end
        end

        describe ".save" do

          before do
            Person.safely.create(:ssn => "432-97-1113")
          end

          context "when a mongodb error occurs" do

            let(:person) do
              Person.new(:ssn => "432-97-1113")
            end

            it "should fail silently" do
              person.unsafely.save(:ssn => "432-97-1113").should be_true
            end

            it "should still use defaults for subsequent requests" do
              person.unsafely.save(:ssn => "432-97-1113")
              lambda {
                Person.create(:ssn => "432-97-1113")
              }.should raise_error(Mongo::OperationFailure)
            end
          end
        end

    end
  end
end
