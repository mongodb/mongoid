require "spec_helper"

describe Mongoid::Attributes do

  context "when persisting nil attributes" do

    let!(:person) do
      Person.create(:score => nil, :ssn => "555-66-7777")
    end

    after do
      Person.delete_all
      Agent.delete_all
    end

    it "has an entry in the attributes" do
      person.reload.attributes.should have_key(:score)
    end

    it "has a nil value" do
      person.reload[:score].should be_nil
    end
  end

  context "when default values are defined" do

    let(:person) do
      Person.create
    end

    it "does not override the default" do
      person.last_drink_taken_at.should == 1.day.ago.to_date
    end
  end

  context "when persisting nested with accepts_nested_attributes_for" do

    context "when the nested document is an embeds_many" do

      # before do
        # @survey = Survey.new
        # @survey.questions.build(:content => 'Do you like cheesecake ?')
        # @survey.questions.build(:content => 'Do you like cuppcake ?')
        # @survey.questions.build(:content => 'Do you like ace cream ?')
        # @survey.save
        # @attributes = {
          # "0" => { :content => "lorem", "_destroy" => "true" },
          # "1" => { :content => "lorem", "_destroy" => "true" },
          # "2" => { :content => "Do you like ice cream ?", "_destroy" => "" },
          # "new_record" => { :content => "Do you like carrot cake ?" }
        # }
      # end

      it "adds/updates/removes embedded documents" do
        pending "Durran: NestedAttributes Refactoring"
        @survey.update_attributes(:questions_attributes => @attributes)
        @survey.reload
        @survey.questions.size.should == 2
        @survey.questions.first.content.should == "Do you like ice cream ?"
        @survey.questions.last.content.should == "Do you like carrot cake ?"
      end
    end

    context "when the nested document is an embeds_one" do

      let(:person) do
        Person.create
      end

      it "adds an embedded document" do
        person.update_attributes(:pet_attributes => {"name" => "Smoke"})
        person.pet.name.should == "Smoke"
      end

      it "updates an embedded document" do
        person.create_pet(:name => "Smoke")
        person.update_attributes(:pet_attributes => {"name" => "Chloe"})
        person.pet.name.should == "Chloe"
      end

      it "deletes an embedded document" do
        pending "Durran: NestedAttributes Refactoring"
        person.create_pet(:name => "Smoke")
        person.update_attributes(:pet_attributes => {"_destroy" => "1"})
        person.pet.should be_nil
      end
    end

    context "when the nested document is a references_many" do

      # before do
        # @agent = Agent.new
        # post1 = @agent.posts.build(:title => "Post 1")
        # post2 = @agent.posts.build(:title => "Post 2")
        # post3 = @agent.posts.build(:title => "Post 3")
        # @agent.save
        # @agent.reload
        # @attributes = {
          # "0" => { 'id' => post1.id.to_s, 'title' => "lorem", "_destroy" => "true" },
          # "1" => { 'id' => post2.id.to_s, 'title' => "lorem", "_destroy" => "true" },
          # "2" => { 'id' => post3.id.to_s, 'title' => "Do you like ice cream ?", "_destroy" => "" },
          # "new_record" => { 'title' => "Do you like carrot cake ?" }
        # }
      # end

      it "adds/updates/removes related documents" do
        pending "Durran: NestedAttributes Refactoring"
        @agent.update_attributes(:posts_attributes => @attributes)
        @agent.posts.size.should == 2
        Set.new(["Do you like ice cream ?", "Do you like carrot cake ?"]).should ==
          Set.new(@agent.posts.map(&:title))
      end
    end

    context "when the nested document is a references_one" do
      let(:person) { Person.create }

      it "adds a document" do
        person.update_attributes(:game_attributes => {"score" => "78"})
        person.game.score.should == 78
      end

      it "updates a document" do
        pending "Durran: NestedAttributes Refactoring"
        person.create_game(:score => "78")
        person.update_attributes(:game_attributes => {"score" => "67"})
        person.game.score.should == 67
      end

      it "deletes a document" do
        pending "Durran: NestedAttributes Refactoring"
        person.create_game(:score => "78")
        person.update_attributes(:game_attributes => {"_destroy" => "1"})
        person.game.should be_nil
      end
    end
  end
end
