# A simplistic mock object to stand in for Rails, instead of adding an
# otherwise unnecessary dependency on Rails itself.

module Rails
  def self.logger
    ::Logger.new($stdout)
  end
end
