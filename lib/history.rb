class History
  include Enumerable

  def initialize
    @unique_id = 0
    @completed = []
    @pending = []
    @method_names = {}
    @arguments = {}
    @returns = {}
    @before = {}
    @after = {}
    # @after_reduced = {}
  end

  def initialize_copy(other)
    super
    @completed = @completed.clone
    @pending = @pending.clone
    @method_names = @method_names.clone
    @arguments = @arguments.clone
    @returns = @returns.clone
    @before = @before.clone
    @after = @after.clone
    # @after_reduced = @after_reduced.clone
    @before.each {|id,ops| @before[id] = ops.clone}
    @after.each {|id,ops| @after[id] = ops.clone}
    # @after_reduced.each {|id,ops| @after_reduced[id] = ops.clone}
  end

  def each(&block)
    if block_given?
      @completed.each(&block)
      @pending.each(&block)
      self
    else
      to_enum
    end
  end

  def empty?;             count == 0 end
  def include?(id)        !@method_names[id].nil? end
  def pending?(id)        @returns[id].nil? end
  def completed?(id)      !pending?(id) end
  def method_name(id)     @method_names[id] end
  def arguments(id)       @arguments[id] end
  def returns(id)         @returns[id] end
  def before(id)          @before[id] end
  def after(id)           @after[id] end
  # def after_reduced(id)   @after_reduced[id] end
  def minimals;           select {|id| before(id).empty? } end
  def maximals;           select {|id| after(id).empty? } end

  def start(m,*args)      h = clone; id = h.start!(m,*args); [h,id] end
  def complete(id,*rets)  clone.complete!(id,*rets) end
  def remove(id)          clone.remove!(id) end

  def update(act,*args)
    case act
    when :start;      start!(args[0], args.drop(1))
    when :complete;   complete!(args[0], args.drop(1))
    else              fail "Unexpected history update."
    end
  end

  def to_s; to_interval_s end

  def method_names; map{|id| method_name(id)}.uniq end
  def values; map{|id| arguments(id)+(returns(id)||[])}.flatten(1).uniq end

  def intervals
    past = @before.values.map{|ops| ops.count}.uniq.sort.map.with_index{|c,i| [c,i]}.to_h
    future = @after.values.map{|ops| ops.count}.uniq.sort.reverse.map.with_index{|c,i| [c,i]}.to_h
    fail "Uh oh..." unless (n = past.count) == future.count
    [n, each.map{|id| [id,[past[before(id).count], future[after(id).count]]]}.to_h]
  end

  def label(id)
    str = ""
    str << @method_names[id]
    str << "(#{@arguments[id] * ", "})" unless @arguments[id].empty?
    if pending?(id)
      str << "*"
    elsif !@returns[id].empty?
      str << " => #{@returns[id] * ", "}"
    end
    str
  end

  def to_interval_s(scale: 2)
    n, imap = intervals
    ops = each.map{|id| [id,["[#{id}]",label(id)]]}.to_h
    id_j = ops.values.map{|id,_| id.length}.max
    op_j = ops.values.map{|_,op| op.length}.max
    each.map do |id|
      i, j = imap[id].map{|x| x*scale}
      "#{ops[id][0].ljust(id_j)} #{ops[id][1].ljust(op_j)}  #{' ' * i}#{'#' * (j-i+1)}"
    end * "\n"
  end

  def self.from_execution_log(input)
    h = new
    ids = {}
    input.each do |line|
      line.chomp!
      next if line.empty?
      if line.match(/\A\[(?'id'\d+)\]\s*call \s*(?'method'\w+)(\((?'values'\w+(\s*,\s*\w+)*)?\))?\Z/) do |m|
        id = m[:id].to_i
        fail "Duplicate operation identifier #{id}" if ids.include?(id)
        method = m[:method].to_sym
        values = (m[:values] || "").split(/\s*,\s*/).map(&:strip).map(&:to_sym)
        ids[id] = h.start!(method,*values)
        true
      end
      elsif line.match(/\A\[(?'id'\d+)\]\s*ret(urn)?\s*(?'values' \w+(\s*,\s*\w+)*)?\Z/) do |m|
        id = m[:id].to_i
        values = (m[:values] || "").split(/\s*,\s*/).map(&:strip).map(&:to_sym)
        h.complete!(ids[id],*values)
        ids.delete id
        true
      end
      else
        fail "Unexpected action '#{line}'"
      end
      yield h if block_given?
    end
    h
  end

  def start!(m,*args)
    id = (@unique_id += 1)
    @pending << id
    @method_names[id] = m.to_s
    @arguments[id] = args
    @returns[id] = nil
    @before[id] = []
    @before[id].push *@completed
    @after[id] = []
    # @after_reduced[id] = []
    @completed.each {|c| @after[c] << id}
    # @completed.each {|c| @after_reduced[c] << id if @after[c].all? {|p| pending?(p)}}
    id
  end

  def complete!(id,*rets)
    fail "Operation #{id} not present."     unless include?(id)
    fail "Operation #{id} already updated." unless pending?(id)
    @pending.delete id
    @completed << id
    @returns[id] = rets
    self
  end

  def remove!(id)
    fail "Operation #{id} not present." unless include?(id)
    @completed.delete id
    @pending.delete id
    @method_names.delete id
    @arguments.delete id
    @returns.delete id
    @before.delete id
    @before.each {|_,ops| ops.delete id}
    @after.delete id
    @after.each {|_,ops| ops.delete id}
    # @after_reduced.delete id
    # @after_reduced.each {|_,ops| ops.delete id}
    self
  end

  def linearizations
    Enumerator.new do |y|
      partials = []
      partials << [[], self]

      while !partials.empty? do
        seq, h = partials.shift
        if h.empty?
          y << seq
        else
          h.minimals.each do |id|
            partials << [seq + [id], h.remove(id)]
          end
        end
      end
    end
  end

end
