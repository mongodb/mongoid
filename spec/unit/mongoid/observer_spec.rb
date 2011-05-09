require "spec_helper"

describe Mongoid::Observer do

  before do
    [ Actor, Actress ].each(&:delete_all)
  end

  after do
    CallbackRecorder.instance.reset
  end

  it "is an instance of an active model observer" do
    ActorObserver.instance.should be_a_kind_of(ActiveModel::Observer)
  end

  context "when the observer has descendants" do

    let!(:observer) do
      ActorObserver.instance
    end

    let(:actor) do
      Actor.create!(:name => "Johnny Depp")
    end

    let(:actress) do
      Actress.create!(:name => "Tina Fey")
    end

    it "observes descendent class" do
      actor and observer.last_after_create_record.try(:name).should == actor.name
      actress and observer.last_after_create_record.try(:name).should == actress.name
    end
  end

  it "observes after_initialize" do
    observer = CallbackRecorder.instance
    actor = Actor.new

    observer.last_callback.should == :after_initialize
    observer.call_count[:after_initialize].should == 1
    observer.last_record[:after_initialize].should eq(actor)
  end

  [:before_create, :after_create, :around_create, :before_save, :after_save, :around_save].each do |callback|
    it "observes #{callback} when creating" do
      observer = CallbackRecorder.instance
      actor = Actor.create!
      actor.should be_persisted

      observer.call_count[callback].should == 1
      observer.last_record[callback].should eq(actor)
    end
  end

  [:before_update, :after_update, :around_update, :before_save, :after_save, :around_save].each do |callback|
    it "observes #{callback} when updating" do
      observer = CallbackRecorder.instance
      actor = Actor.create!
      observer.reset
      actor.update_attributes! :name => "Johnny Depp"
      actor.should be_persisted

      observer.call_count[callback].should == 1
      observer.last_record[callback].should eq(actor)
    end
  end

  [:before_destroy, :after_destroy, :around_destroy].each do |callback|
    it "observes #{callback}" do
      observer = CallbackRecorder.instance
      actor = Actor.create!.tap(&:destroy)
      actor.should be_destroyed

      observer.call_count[callback].should == 1
      observer.last_record[callback].should eq(actor)
    end
  end

  [:before_validation, :after_validation].each do |callback|
    it "observes #{callback}" do
      observer = CallbackRecorder.instance
      actor = Actor.new
      validity = actor.valid?
      validity.should be_true

      observer.call_count[callback].should == 1
      observer.last_record[callback].should eq(actor)
    end
  end
end
