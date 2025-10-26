#!/usr/bin/env ruby

require_relative '../lib/benchmarks/xml_writer_benchmark'
require_relative '../lib/benchmarks/memory_usage_demo'
require_relative '../lib/benchmarks/json_xml_benchmark'

# Ensure we're in the project root directory
Dir.chdir(File.expand_path('..', __dir__))

# Run benchmarks if this file is executed directly
if __FILE__ == $0
  puts "\n" + "=" * 70
  puts "COMPREHENSIVE BENCHMARKS"
  puts "Memory-Efficient XML Generation with Yajl JSON Parsing"
  puts "=" * 70

  # Run JSON to XML benchmark first (demonstrates Yajl performance)
  json_benchmark = JSONXMLBenchmark.new
  json_benchmark.run_benchmark

  # Run XML writer comparison benchmarks
  xml_benchmark = XMLWriterBenchmark.new
  xml_benchmark.run_all_benchmarks

  # Run memory efficiency demonstration
  memory_demo = MemoryUsageDemo.new
  memory_demo.demonstrate_memory_efficiency

  puts "\n" + "=" * 70
  puts "ALL BENCHMARKS COMPLETED"
  puts "=" * 70
end
