require "spec_helper"

describe Mongoid::Attributes do

  context "when persisting nil attributes" do

    before do
      @person = Person.create(:score => nil, :ssn => "555-66-7777")
    end

    after do
      Person.delete_all
    end

    it "the field should exist with a nil value" do
      from_db = Person.find(@person.id)
      from_db.attributes.has_key?(:score).should be_true
    end

  end
  
  context "when persisting nested attributes" do
    
    before do
      @survey = Survey.new
      3.times do
        @question = @survey.questions.build
        4.times { @question.answers.build }
      end
    end
    
  end
  
  context "when persisting nested with accepts_nested_attributes_for" do
    
    before do
      @survey = Survey.new
      @survey.questions.build(:content => 'Do you like cheesecake ?')
      @survey.questions.build(:content => 'Do you like cuppcake ?')
      @survey.questions.build(:content => 'Do you like ace cream ?')
      @survey.save
      @attributes = {
        "0" => { :content => "lorem", "_destroy" => "true" },
        "1" => { :content => "lorem", "_destroy" => "true" },
        "2" => { :content => "Do you like ice cream ?" },
        "new_record" => { :content => "Do you carrot cake ?" }
      }
    end
    
    it "adds/updates/removes embedded documents" do
      @survey.update_attributes(:questions_attributes => @attributes)
      @survey.reload
      @survey.questions.size.should == 2
      @survey.questions.first.content.should == "Do you like ice cream ?"
    end
    
  end

end
