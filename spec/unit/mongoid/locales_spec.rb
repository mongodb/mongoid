require "spec_helper"

describe "locales" do

  Dir.glob("lib/config/locales/*.yml").sort.each do |file|
    it "no parsing errors for locale #{file}" do
      expect { YAML.load_file(file) }.to_not raise_error
    end
  end
end
