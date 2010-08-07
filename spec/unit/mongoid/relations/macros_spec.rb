require "spec_helper"

describe Mongoid::Relations::Macros do

  let(:klass) do
    Class.new do
      include Mongoid::Relations::Macros
    end
  end

  context ".embedded_in" do

    it "defines the macro" do
      klass.should respond_to(:embedded_in)
    end
  end

  context ".embeds_many" do

    it "defines the macro" do
      klass.should respond_to(:embeds_many)
    end
  end

  context ".embeds_one" do

    it "defines the macro" do
      klass.should respond_to(:embeds_one)
    end
  end

  context ".referenced_in" do

    it "defines the macro" do
      klass.should respond_to(:referenced_in)
    end
  end

  context ".references_many" do

    it "defines the macro" do
      klass.should respond_to(:references_many)
    end
  end

  context ".references_one" do

    it "defines the macro" do
      klass.should respond_to(:references_one)
    end
  end
end
