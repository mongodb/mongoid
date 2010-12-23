require "spec_helper"

describe Mongoid::DefaultScope do

  class Acolyte
    include Mongoid::Document
    field :status
    field :name

    scope :active, where(:status => "active")

    default_scope asc(:name)
  end

  describe ".default_scope" do

    subject { Acolyte.all }

    its(:options) { should == {:sort => [[:name, :asc]]} }

  end

  context "combined with a named scope" do

    subject { Acolyte.active }

    its(:options) { should == {:sort => [[:name, :asc]]} }
    its(:selector) { should == {:status => "active"} }

  end

end
