#!/usr/bin/env ruby

require_relative '../lib/benchmarks/xml_writer_benchmark'
require_relative '../lib/benchmarks/memory_usage_demo'

# Ensure we're in the project root directory
Dir.chdir(File.expand_path('..', __dir__))

# Run benchmarks if this file is executed directly
if __FILE__ == $0
  benchmark = XMLWriterBenchmark.new
  benchmark.run_all_benchmarks

  memory_demo = MemoryUsageDemo.new
  memory_demo.demonstrate_memory_efficiency
end
