require "spec_helper"

describe Mongoid::Callbacks do

  class TestClass
    include Mongoid::Callbacks
  end

  it "CALLBACKS includes all callbacks" do
    Mongoid::Callbacks::CALLBACKS.should =~ TestClass.methods.map(&:to_s).grep(/^(before|after|around)_/).map(&:to_sym).reject do |method|
      # deprecated callbacks
      [:after_validation_on_create, :after_validation_on_update, :before_validation_on_create, :before_validation_on_update].include? method
    end
  end

  describe ".included" do

    before do
      @class = TestClass
    end

    it "includes the before_create callback" do
      @class.should respond_to(:before_create)
    end

    it "includes the after_create callback" do
      @class.should respond_to(:after_create)
    end

    it "includes the before_destroy callback" do
      @class.should respond_to(:before_destroy)
    end

    it "includes the after_destroy callback" do
      @class.should respond_to(:after_destroy)
    end

    it "includes the before_save callback" do
      @class.should respond_to(:before_save)
    end

    it "includes the after_save callback" do
      @class.should respond_to(:after_save)
    end

    it "includes the before_update callback" do
      @class.should respond_to(:before_update)
    end

    it "includes the after_update callback" do
      @class.should respond_to(:after_update)
    end

    it "includes the before_validation callback" do
      @class.should respond_to(:before_validation)
    end

    it "includes the after_validation callback" do
      @class.should respond_to(:after_validation)
    end

    it "includes the after_initialize callback" do
      @class.should respond_to(:after_initialize)
    end
  end

  describe ".after_initialize" do

    let(:game) do
      Game.new
    end

    it "runs after document instantiation" do
      game.name.should == "Testing"
    end
  end

  describe "cascaded callbacks" do

    let(:artist) do
      Artist.new(:name => "Foo Fighters")
    end

    context "on parent update" do

      before do
        artist.save!
        artist.build_instrument(:name => "Piano")
      end

      context "child is new" do

        it "should trigger create" do
          artist.save!
          artist.instrument.name.should == 'PIANO'
        end

        it "should not trigger update" do
          artist.save!
          artist.instrument.key.should_not == 'G#'
        end
      end

      context "child is persisted" do

        before do
          artist.save!
        end

        context "child is dirty" do

          before do
            artist.instrument.name = 'Tuba'
          end

          it "should trigger update" do
            artist.save!
            artist.instrument.key.should == 'G#'
          end
        end

        context "child is not dirty" do

          it "should not trigger update" do
            artist.save!
            artist.instrument.key.should_not == 'G#'
          end
        end
      end
    end

    context "when enabled" do

      let(:label) do
        Label.new(:name => "Tower Records")
      end

      let(:instrument) do
        Instrument.new(:name => "Harpsichord")
      end

      before do
        artist.labels << label
        artist.instrument = instrument
      end

      context "embeds_many" do

        it "should cascade callbacks" do
          label.expects(:after_save_stub)
          artist.save!
        end
      end

      context "embeds_one" do

        it "should cascade callbacks" do
          instrument.expects(:after_save_stub)
          artist.save!
        end
      end
    end

    context "when disabled" do

      let(:song) do
        Song.new
      end

      let(:address) do
        Address.new
      end

      before do
        artist.songs << song
        artist.address = address
      end

      context "embeds_many" do

        it "should not cascade callbacks" do
          song.expects(:after_save_stub).never
          artist.save!
        end
      end

      context "embeds_one" do

        it "should not cascade callbacks" do
          address.expects(:after_save_stub).never
          artist.save!
        end
      end
    end
  end

  describe ".before_create" do

    before do
      @artist = Artist.new(:name => "Depeche Mode")
    end

    context "callback returns true" do
      before do
        @artist.expects(:before_create_stub).returns(true)
      end

      it "should get saved" do
        @artist.save.should == true
        @artist.persisted?.should == true
      end
    end

    context "callback returns false" do
      before do
        @artist.expects(:before_create_stub).returns(false)
      end

      it "should not get saved" do
        @artist.save.should == false
        @artist.persisted?.should == false
      end
    end
  end
end
