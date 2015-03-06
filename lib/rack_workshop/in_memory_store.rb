class InMemoryStore
  def initialize
    @calls = {}
  end

  def get(thing)
    @calls[thing] if @calls.has_key?(thing)
  end

  def set(thing, value)
    @calls[thing] = value
  end
end
