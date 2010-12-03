require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::Many do

  let(:klass) do
    Mongoid::Relations::Bindings::Referenced::Many
  end

  let(:user) do
    User.new
  end

  let(:description) do
    Description.new
  end

  let(:target) do
    [ description ]
  end

  let(:metadata) do
    User.relations["descriptions"]
  end

  describe "#bind" do

    let(:binding) do
      klass.new(user, target, metadata)
    end

    context "when the documents are bindable" do

      before do
        binding.bind
      end

      it "sets the inverse foreign key" do
        description.user_id.should == user.id
      end
  
      it "sets the inverse relation" do
        description.user.should == user
      end
    end

    context "when the documents are not bindable" do

      it "does nothing" do
        user.descriptions.expects(:<<).never
        binding.bind
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      klass.new(user, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind
        binding.unbind
      end

      it "removes the inverse foreign key" do
        description.user_id.should be_nil
      end
  
      it "removes the inverse relation" do
        description.user.should be_nil
      end
    end

    context "when the documents are not unbindable" do
      
      it "does nothing" do
        user.expects(:descriptions=).never
        binding.unbind
      end
    end
  end
end
