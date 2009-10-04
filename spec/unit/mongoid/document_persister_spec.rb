require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Persister do

  before do
    @document = stub
    @persister = Mongoid::Persister.new(@document)
  end

  describe "#create" do

    context "callbacks" do

      it "calls before and after create" do
        @persister.expects(:run_callbacks).with(:before_create)
        @persister.expects(:run_callbacks).with(:after_create)
        @persister.create
      end

    end

    context "when document is valid" do

      it "saves the document and returns the document"

    end

    context "when document is not valid" do

      it "returns false"

    end

  end

  describe "#create!" do

  end


  # No callbacks
  describe "#delete" do

  end

  # Has callbacks
  describe "#destroy" do

  end

  describe "#save" do

  end

  describe "#save!" do

  end

  describe "#udpate_attributes" do

  end

  describe "#update_attributes!" do

  end


end

__END__

def create
  @post = Post.new
  if @post.save
  else
    render :action => :new
  end
end
