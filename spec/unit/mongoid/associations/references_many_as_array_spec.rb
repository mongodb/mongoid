require "spec_helper"

describe Mongoid::Associations::ReferencesManyAsArray do

  let(:block) do
    Proc.new do
      def extension
        "Testing"
      end
    end
  end

  [
    ["with inverse association set", :people],
    ["with no inverse association",   nil]
  ].each do |description, inverse_of|

    context description do
      let(:options) do
        Mongoid::Associations::Options.new(
          :name => :preferences,
          :foreign_key => "preference_ids",
          :extend => block,
          :inverse_of => inverse_of
        )
      end

      describe "#<<" do

        context "when the parent document is new" do

          let(:person) do
            Person.new
          end

          let(:preference) do
            Preference.new(:name => "Brightness")
          end

          before do
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options
            )
            @association << preference
          end

          it "appends the document to the association" do
            @association.target.first.should == preference
          end

          it "adds the id to the association ids" do
            person.preference_ids.should include(preference.id)
          end

          it "doesn't save the child document" do
            child = Preference.new(:name => "Saturation")
            child.expects(:save).never
            @association << child
          end

          if inverse_of
            it "adds the reverse association id" do
              preference.person_ids.should include(person.id)
            end
          end
        end

        context "when the parent document is not new" do

          let(:person) do
            Person.new
          end

          let(:preference) do
            Preference.new(:name => "Brightness")
          end

          before do
            person.instance_variable_set(:@new_record, false)
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options, []
            )
            @association << preference
          end

          it "appends the document to the association" do
            @association.target.first.should == preference
          end

          it "adds the id to the association ids" do
            person.preference_ids.should include(preference.id)
          end

          it "saves the child document" do
            child = Preference.new(:name => "Saturation")
            child.expects(:save).returns(true)
            @association << child
          end

          if inverse_of
            it "adds the reverse association id" do
              preference.person_ids.should include(person.id)
            end
          end

          it "saves the parent" do
            person.expects(:save)
            person.preferences << Preference.new(:name => "Utter darkness")
          end
        end
      end

      describe "#build" do

        context "when the parent is new" do

          let(:person) do
            Person.new
          end

          before do
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options
            )
            @preference = @association.build(:name => "Brightness")
          end

          it "appends the document to the association" do
            @association.target.first.should == @preference
          end

          it "adds the id to the association ids" do
            person.preference_ids.should include(@preference.id)
          end

          if inverse_of
            it "adds the reverse association id" do
              @preference.person_ids.should include(person.id)
            end
          end
        end

        context "when the parent is not new" do

          let(:person) do
            Person.new
          end

          before do
            person.instance_variable_set(:@new_record, false)
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options, []
            )
            @preference = @association.build(:name => "Brightness")
          end

          it "appends the document to the association" do
            @association.target.first.should == @preference
          end

          it "adds the id to the association ids" do
            person.preference_ids.should include(@preference.id)
          end

          if inverse_of
            it "adds the reverse association id" do
              @preference.person_ids.should include(person.id)
            end
          end
        end
      end

      describe "#create" do

        context "when the parent is new" do

          let(:person) do
            Person.new
          end

          before do
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options
            )
            @preference = @association.create(:name => "Brightness")
          end

          it "appends the document to the association" do
            @association.target.first.should == @preference
          end

          it "adds the id to the association ids" do
            person.preference_ids.should include(@preference.id)
          end

          if inverse_of
            it "adds the reverse association id" do
              @preference.person_ids.should include(person.id)
            end
          end

          it "saves the association" do
            @preference.new_record?.should == false
          end
        end

        context "when the parent is not new" do

          let(:person) do
            Person.new
          end

          before do
            person.instance_variable_set(:@new_record, false)
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options, []
            )
            @preference = @association.create(:name => "Brightness")
          end

          it "appends the document to the association" do
            @association.target.first.should == @preference
          end

          it "adds the id to the association ids" do
            person.preference_ids.should include(@preference.id)
          end

          if inverse_of
            it "adds the reverse association id" do
              @preference.person_ids.should include(person.id)
            end
          end

          it "saves the association" do
            @preference.new_record?.should == false
          end
        end
      end

      describe "#create!" do

        context "when validation passes" do

          let(:person) do
            Person.new
          end

          before do
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options
            )
            @preference = @association.create!(:name => "Brightness")
          end

          it "saves the association" do
            @preference.new_record?.should == false
          end
        end

        context "when validation fails" do

          let(:person) do
            Person.new
          end

          before do
            person.instance_variable_set(:@new_record, false)
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options, []
            )
          end

          it "raises an error" do
            lambda { @association.create!(:name => "B") }.should
            raise_error(Mongoid::Errors::Validations)
          end
        end
      end

      describe "#initialize" do

        let(:person) do
          Person.new
        end

        context "when a target is not provided" do

          before do
            person.preference_ids = [
              "4c52c439931a90ab29000003",
              "4c52c439931a90ab29000004",
              "4c52c439931a90ab29000005"
            ]
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options
            )
            @criteria = Preference.any_in(
              :_id => [
                BSON::ObjectId("4c52c439931a90ab29000003"),
                BSON::ObjectId("4c52c439931a90ab29000004"),
                BSON::ObjectId("4c52c439931a90ab29000005")
              ]
            )
          end

          it "sets the association options" do
            @association.options.should == options
          end

          it "sets the target to the criteria for finding by ids" do
            @association.target.should == @criteria
          end
        end

        context "when a target is provided" do
          before do
            @preferences = [
              Preference.new,
              Preference.new
            ]
            @association = Mongoid::Associations::ReferencesManyAsArray.new(
              person, options, @preferences
            )
          end

          it "sets the target to the entries provided" do
            @association.target.should == @preferences
          end
        end
      end

      describe "#concat" do

        let(:person) do
          Person.new
        end

        let(:preference) do
          Preference.new(:name => "Brightness")
        end

        before do
          @association = Mongoid::Associations::ReferencesManyAsArray.new(
            person, options
          )
          @association.concat(preference)
        end

        it "delegates to <<" do
          @association.target.first.should == preference
        end
      end

      describe ".instantiate" do

        let(:person) do
          Person.new
        end

        context "when a target is not provided" do

          before do
            person.preference_ids = [
              "4c52c439931a90ab29000003",
              "4c52c439931a90ab29000004",
              "4c52c439931a90ab29000005"
            ]
            @association = Mongoid::Associations::ReferencesManyAsArray.instantiate(
              person, options
            )
            @criteria = Preference.any_in(
              :_id => [
                BSON::ObjectId("4c52c439931a90ab29000003"),
                BSON::ObjectId("4c52c439931a90ab29000004"),
                BSON::ObjectId("4c52c439931a90ab29000005")
              ]
            )
          end

          it "sets the association options" do
            @association.options.should == options
          end

          it "sets the target to the criteria for finding by ids" do
            @association.target.should == @criteria
          end
        end

        context "when a target is provided" do
          before do
            @preferences = [
              Preference.new,
              Preference.new
            ]
            @association = Mongoid::Associations::ReferencesManyAsArray.instantiate(
              person, options, @preferences
            )
          end

          it "sets the target to the entries provided" do
            @association.target.should == @preferences
          end
        end
      end

      describe "#method_missing" do

        let(:person) do
          Person.new
        end

        context "when target is a criteria" do

          before do
            person.preference_ids = [
              "4c52c439931a90ab29000003",
              "4c52c439931a90ab29000004",
              "4c52c439931a90ab29000005"
            ]
            @association = Mongoid::Associations::ReferencesManyAsArray.instantiate(
              person, options
            )
          end

          it "executes the criteria and sends to the result" do
            Preference.expects(:any_in).with(
              :_id => [
                BSON::ObjectId("4c52c439931a90ab29000003"),
                BSON::ObjectId("4c52c439931a90ab29000004"),
                BSON::ObjectId("4c52c439931a90ab29000005")
              ]
            ).returns([])
            @association.entries.should == []
          end
        end

        context "when target is an array" do

        end
      end

      describe "#push" do

        let(:person) do
          Person.new
        end

        let(:preference) do
          Preference.new(:name => "Brightness")
        end

        before do
          @association = Mongoid::Associations::ReferencesManyAsArray.new(
            person, options
          )
          @association.push(preference)
        end

        it "delegates to <<" do
          @association.target.first.should == preference
        end
      end

      describe ".update" do

        before do
          @first = Preference.new
          @second = Preference.new
          @related = [@first, @second]
          @parent = Person.new
          @proxy = Mongoid::Associations::ReferencesManyAsArray.update(@related, @parent, options)
        end

        it "sets the related object id on the parent" do
          @first.person_ids.should include(@parent.id)
          @second.person_ids.should include(@parent.id)
        end

        it "sets the target" do
          @proxy.target.should == @related
        end

        it "sets the reverse association ids" do
          @parent.preference_ids.should include(@first.id)
          @parent.preference_ids.should include(@second.id)
        end
      end
    end
  end
end
