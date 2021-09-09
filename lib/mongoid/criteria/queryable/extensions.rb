# frozen_string_literal: true

if defined?(ActiveSupport)
  unless defined?(ActiveSupport::TimeWithZone)
    require "active_support/time_with_zone"
  end
  require "mongoid/criteria/queryable/extensions/time_with_zone"
end

require "time"
require "mongoid/criteria/queryable/extensions/object"
require "mongoid/criteria/queryable/extensions/array"
require "mongoid/criteria/queryable/extensions/big_decimal"
require "mongoid/criteria/queryable/extensions/boolean"
require "mongoid/criteria/queryable/extensions/date"
require "mongoid/criteria/queryable/extensions/date_time"
require "mongoid/criteria/queryable/extensions/hash"
require "mongoid/criteria/queryable/extensions/nil_class"
require "mongoid/criteria/queryable/extensions/numeric"
require "mongoid/criteria/queryable/extensions/range"
require "mongoid/criteria/queryable/extensions/regexp"
require "mongoid/criteria/queryable/extensions/set"
require "mongoid/criteria/queryable/extensions/string"
require "mongoid/criteria/queryable/extensions/symbol"
require "mongoid/criteria/queryable/extensions/time"
