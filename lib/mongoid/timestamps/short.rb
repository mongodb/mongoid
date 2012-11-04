# encoding: utf-8
module Mongoid
  module Timestamps
    module Short
      extend ActiveSupport::Concern
      include Created::Short
      include Updated::Short
    end
  end
end
