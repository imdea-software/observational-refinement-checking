class MyStack
  attr_accessor :contents, :gen
  def initialize
    @contents = []
    @gen = Random.new
  end
  def to_s; "My Stack" end
  def add(val)
    sleep @gen.rand(0.2)
    @contents.push val
    sleep @gen.rand(0.1)
    nil
  end
  def remove
    sleep @gen.rand(0.02)
    val = @contents.pop
    sleep @gen.rand(0.01)
    val || :empty
  end
end