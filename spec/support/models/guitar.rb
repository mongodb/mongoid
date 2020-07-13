# frozen_string_literal: true
# encoding: utf-8

class Guitar < Instrument
    self.discriminator_key = "dkey"
end
