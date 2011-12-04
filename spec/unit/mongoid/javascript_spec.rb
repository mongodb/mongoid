require "spec_helper"

describe Mongoid::Javascript do

  let(:js) do
    Mongoid::Javascript
  end

  describe ".aggregate" do

    it "returns the aggregate function" do
      js.aggregate.should == "function(obj, prev) { prev.count++; }"
    end
  end

  describe ".group" do

    it "returns the group function" do
      js.group.should == "function(obj, prev) { prev.group.push(obj); }"
    end
  end

  describe ".max" do

    it "returns the max function" do
      js.max.should == "function(obj, prev) { if (obj.[field] && prev.max == 'start') { " +
        "prev.max = obj.[field]; } if (obj.[field] && prev.max < obj.[field]) { prev.max = " +
        "obj.[field]; } }"
    end
  end

  describe ".min" do

    it "returns the min function" do
      js.min.should == "function(obj, prev) { if (obj.[field] && prev.min == 'start') { " +
        "prev.min = obj.[field]; } if (obj.[field] && prev.min > obj.[field]) { prev.min " +
        "= obj.[field]; } }"
    end
  end

  describe ".sum" do

    it "returns the sum function" do
      js.sum.should == "function(obj, prev) { if (prev.sum == 'start') " +
      "{ prev.sum = 0; } if (obj.[field]) { prev.sum += obj.[field]; } }"
    end
  end
  
  describe ".compound" do
    let(:fields) do
      {:age => [:min, :max, :sum], :height => "<custom js>" }
    end
    
    let(:js_str) do
      remove_whitespace <<-EOS
      function(obj, prev) {
        if (obj.age && prev.age_min == 'start') {
            prev.age_min = obj.age;
        }
        if (obj.age && prev.age_min > obj.age) {
            prev.age_min = obj.age;
        }
        if (obj.age && prev.age_max == 'start') {
            prev.age_max = obj.age;
        }
        if (obj.age && prev.age_max < obj.age) {
            prev.age_max = obj.age;
        }
        if (prev.age_sum == 'start') {
            prev.age_sum = 0;
        }
        if (obj.age) {
            prev.age_sum += obj.age;
        }
        <custom js>
      }
      EOS
    end
    
    it "returns a compound function" do
      remove_whitespace(js.compound(fields)).should == js_str
    end
  end
  
  describe ".compound_finalize" do
    let(:fields) do
      {:age => [:min, :max, :sum], :height => "<custom js>" }
    end
    
    let(:js_str) do
      remove_whitespace <<-EOS
      function(obj, prev) {
          if (obj.age_min == 'start' || isNaN(obj.age_min)) {
              obj.age_min = 0;
          }
          return obj;
      	if (obj.age_max == 'start' || isNaN(obj.age_max)) {
              obj.age_max = 0;
          }
          return obj;
      	if (obj.age_sum == 'start' || isNaN(obj.age_sum)) {
              obj.age_sum = 0;
          }
          return obj;
      	<custom js>
      }
      EOS
    end

    it "returns a compound finalize function" do
      remove_whitespace(js.compound_finalize(fields)).should == js_str
    end
  end
end
