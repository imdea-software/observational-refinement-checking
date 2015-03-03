#!/usr/bin/env ruby

require_relative 'prelude'

require_relative 'monitored_object'
require_relative 'randomized_tester'
require_relative 'log_reader_writer'
require_relative 'implementations'

def parse_options
  options = OpenStruct.new
  options.destination = "data/histories/generated/"
  options.objects = []
  options.num_executions = 10
  options.num_threads = 7
  options.time_limit = nil
  options.operation_limit = 1000

  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename $0} [options] OBJECT"

    opts.separator ""

    opts.on("-h", "--help", "Show this message.") do
      puts opts
      exit
    end

    opts.on("-d", "--destination DIR", "Where to put the files.") do |d|
      options.destination = d
    end

    opts.separator ""
    opts.separator "Some useful limits:"

    opts.on("-e", "--executions N", Integer, "Limit to N executions (default #{options.num_executions}).") do |n|
      options.num_executions = n
    end

    opts.on("-n", "--threads N", Integer, "Limit to N threads (default #{options.num_threads}).") do |n|
      options.num_threads = n
    end

    opts.on("-t", "--time N", Float, "Limit to N seconds (default #{options.time_limit || "-"}).") do |n|
      options.time_limit = n
    end

    opts.on("-o", "--operations N", Integer, "Limit to N operations (default #{options.operation_limit}).") do |n|
      options.operation_limit = n
    end

  end.parse!
  options
end


begin
  impl = ARGV.first
  options = parse_options
  options.impl = Implementations.get(ARGV.first, num_threads: options.num_threads)
  tester = RandomizedTester.new

  puts "Generating random #{options.num_threads}-thread (max) executions for #{impl}"
  print "[#{"." * options.num_executions}]"
  print "\033[<#{options.num_executions+1}>D"

  dest_dir = File.join(options.destination, "#{impl}")
  Dir.mkdir(dest_dir) unless Dir.exists?(dest_dir)
  idx_width = (options.num_executions - 1).to_s.length

  options.num_executions.times do |i|
    object = options.impl.call()
    log_file = File.join(dest_dir, "#{impl}.#{i.to_s.rjust(idx_width,'0')}.log")

    LogReaderWriter.new(log_file, object.class.spec) do |logger|
      tester.run(
        MonitoredObject.new(object, logger),
        options.num_threads,
        operation_limit: options.operation_limit,
        time_limit: options.time_limit
      )
    end
    print "#"
  end
  puts "]"

end
