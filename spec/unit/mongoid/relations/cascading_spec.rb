require "spec_helper"

describe Mongoid::Relations::Cascading do

  describe ".cascade" do

    let(:klass) do
      c = Class.new
      c.send(:include, Mongoid::Document)
      c
    end

    context "when a dependent option is provided" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          :name => :posts,
          :dependent => :destroy,
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      let!(:cascaded) do
        klass.cascade(metadata)
      end

      it "adds the action to the cascades" do
        klass.cascades.should include("posts")
      end

      it "returns self" do
        cascaded.should == klass
      end
    end

    context "when no dependent option is provided" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          :name => :posts,
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      let!(:cascaded) do
        klass.cascade(metadata)
      end

      it "does not add an action to the cascades" do
        klass.cascades.should_not include("posts")
      end

      it "returns self" do
        cascaded.should == klass
      end
    end
  end
end
