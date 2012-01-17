require "spec_helper"

describe Mongoid::MultiDatabase do

  let(:klass) do
    Class.new do
      include Mongoid::Document
    end
  end

  describe ".database" do

    before do
      klass.set_database :secondary
    end

    it "sets the database key on the class" do
      klass.database.should eq("secondary")
    end
  end
end
