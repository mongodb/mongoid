# frozen_string_literal: true
# encoding: utf-8

# Copyright (C) 2022 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongoid

  # @api private
  module Utils

    # This function should be used if you need to measure time.
    # @example Calculate elapsed time.
    #   starting = Utils.monotonic_time
    #   # do something time consuming
    #   ending = Utils.monotonic_time
    #   puts "It took #{(ending - starting).to_i} seconds"
    #
    # @see https://blog.dnsimple.com/2018/03/elapsed-time-with-ruby-the-right-way/
    #
    # @return [Float] seconds according to monotonic clock
    module_function def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
