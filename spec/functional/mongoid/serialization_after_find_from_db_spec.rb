require "spec_helper"

class Root
  include Mongoid::Document
  field :name
  embeds_many :leaves, :class_name => "Leaf"
end

class Leaf
  include Mongoid::Document
  embeds_one :insect, :class_name => "Worm"
  embedded_in :root, :inverse_of => :leaves
end

class Worm
  include Mongoid::Document
  field :name
  embedded_in :leaf, :inverse_of => :insect
end
describe Mongoid::Serialization do
  let(:data) { {:name => "Oak", :leaves => [{:insect => {:name => "Glaurung"}}, {:insect => {:name => ".303 Bookworm"}}]} }
  let(:root) { Root.first(:conditions => {:name => "Oak"}) }

  before do
    Root.new(data).save
  end

  it "serializes the document without the excepted fields after finding it in the database" do
    root.to_json(:except => :_id,
                 :include => { :leaves => {:except => :_id,
                                           :include => { :insect => {:except => :_id
                                                                    }
                                                       }
                                          }
                             }).should == data.to_json
  end
end
