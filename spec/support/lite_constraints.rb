module LiteConstraints
  # Constrain tests that use TimeoutInterrupt to MRI (and Unix)
  def only_mri
    before do
      unless SpecConfig.instance.mri?
        skip "MRI required, we have #{SpecConfig.instance.platform}"
      end
    end
  end

  # This is for marking tests that fail on jruby that should
  # in principle work (as opposed to being fundamentally incompatible
  # with jruby).
  # Often times these failures happen only in Evergreen.
  def fails_on_jruby
    before do
      unless SpecConfig.instance.mri?
        skip "Fails on jruby"
      end
    end
  end
end
