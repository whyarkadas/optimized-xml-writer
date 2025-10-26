require_relative '../utilities/practical_xml_converter'
require 'yajl'
require 'benchmark'

# Benchmark class for JSON to XML conversion using Yajl
# Demonstrates high-performance JSON parsing with streaming XML generation
class JSONXMLBenchmark
  def initialize
    @test_dir = 'output'
    @test_sizes = [10_000, 50_000, 100_000, 500_000]
  end

  def run_benchmark
    puts "\n" + "=" * 70
    puts "JSON to XML Conversion Benchmark (Using Yajl)"
    puts "=" * 70
    puts "Ruby Version: #{RUBY_VERSION}"
    puts "Yajl: High-performance streaming JSON parser"
    puts "=" * 70
    puts

    results = []

    @test_sizes.each do |size|
      puts "\n" + "=" * 70
      puts "Testing with #{format_number(size)} JSON records"
      puts "=" * 70

      result = benchmark_json_to_xml(size)
      results << result

      # Clean up test files
      cleanup_test_file(result[:json_file])
      cleanup_test_file(result[:xml_file])

      GC.start
      sleep 0.5
    end

    print_summary(results)
  end

  private

  def benchmark_json_to_xml(record_count)
    json_file = "#{@test_dir}/test_#{record_count}.jsonl"
    xml_file = "#{@test_dir}/test_#{record_count}.xml"

    puts "\nPhase 1: Generating #{format_number(record_count)} JSON records with Yajl..."
    memory_before_gen = get_memory_usage

    json_generation_time = Benchmark.realtime do
      File.open(json_file, 'w') do |f|
        encoder = Yajl::Encoder.new
        record_count.times do |i|
          record = generate_complex_record(i)
          # Yajl streaming encoder - very fast
          f.puts encoder.encode(record)
          print "." if i % 10_000 == 0 && record_count > 50_000
        end
      end
    end
    puts if record_count > 50_000

    json_file_size = File.size(json_file)
    memory_after_gen = get_memory_usage

    puts "   JSON generation: #{json_generation_time.round(2)}s"
    puts "   JSON file size: #{format_bytes(json_file_size)}"
    puts "   Memory used: #{format_mb(memory_after_gen - memory_before_gen)}"

    puts "\nPhase 2: Converting JSON to XML with Yajl streaming parser..."
    memory_before_convert = get_memory_usage
    memory_peak = memory_before_convert
    records_parsed = 0

    conversion_time = Benchmark.realtime do
      xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'documents')
      xml_writer.start_writing

      # Stream-parse JSONL file using Yajl - extremely memory efficient
      File.foreach(json_file) do |line|
        # Yajl::Parser.parse is much faster than standard JSON.parse
        hash = Yajl::Parser.parse(line.strip)
        xml_writer.write_hash(hash, 'document')
        records_parsed += 1

        # Sample memory periodically
        if records_parsed % 10_000 == 0
          current_memory = get_memory_usage
          memory_peak = [memory_peak, current_memory].max
          print "." if record_count > 50_000
        end
      end

      xml_writer.finish_writing
    end
    puts if record_count > 50_000

    xml_file_size = File.size(xml_file)
    memory_after_convert = get_memory_usage
    memory_peak = [memory_peak, memory_after_convert].max

    records_per_sec = (record_count / conversion_time).round(0)
    throughput_mb = (json_file_size / 1024.0 / 1024.0 / conversion_time).round(2)

    puts "\n" + "-" * 70
    puts "Results:"
    puts "   JSON generation time: #{json_generation_time.round(2)}s"
    puts "   JSON → XML conversion: #{conversion_time.round(2)}s"
    puts "   Total time: #{(json_generation_time + conversion_time).round(2)}s"
    puts "   Records parsed: #{format_number(records_parsed)}"
    puts "   Parsing speed: #{format_number(records_per_sec)} records/sec"
    puts "   Throughput: #{throughput_mb} MB/sec"
    puts "   Memory (generation): #{format_mb(memory_after_gen - memory_before_gen)}"
    puts "   Memory (conversion): #{format_mb(memory_peak - memory_before_convert)}"
    puts "   Memory peak: #{format_mb(memory_peak)}"
    puts "   JSON file: #{format_bytes(json_file_size)}"
    puts "   XML file: #{format_bytes(xml_file_size)}"
    puts "   Size ratio: #{(xml_file_size.to_f / json_file_size * 100).round(1)}%"

    {
      size: record_count,
      json_time: json_generation_time,
      convert_time: conversion_time,
      total_time: json_generation_time + conversion_time,
      records_per_sec: records_per_sec,
      throughput_mb: throughput_mb,
      memory_gen: memory_after_gen - memory_before_gen,
      memory_convert: memory_peak - memory_before_convert,
      memory_peak: memory_peak,
      json_size: json_file_size,
      xml_size: xml_file_size,
      json_file: json_file,
      xml_file: xml_file
    }
  end

  def generate_complex_record(index)
    {
      id: index + 1,
      uuid: "#{format('%08x', rand(0xFFFFFFFF))}-#{format('%04x', rand(0xFFFF))}",
      title: "Document #{index + 1} - #{['Alpha', 'Beta', 'Gamma', 'Delta'].sample}",
      content: "This is a comprehensive content block for document #{index + 1}. " * 3,
      status: ['active', 'pending', 'archived', 'draft'].sample,
      priority: rand(1..5),
      tags: (1..rand(3..8)).map { |n| "tag_#{rand(1..50)}" },
      metadata: {
        created_at: Time.now.to_i - rand(0..31536000),
        updated_at: Time.now.to_i,
        author: "user_#{rand(1..1000)}",
        views: rand(0..100000),
        likes: rand(0..5000),
        comments: rand(0..500),
        shares: rand(0..1000),
        version: "#{rand(1..5)}.#{rand(0..10)}.#{rand(0..20)}"
      },
      nested_structure: {
        level1: {
          level2: {
            level3: {
              deep_value: "nested_#{index}",
              array_data: (1..5).map { |n| { index: n, value: rand(1000), active: [true, false].sample } }
            }
          }
        }
      },
      related_items: (1..rand(2..5)).map do |n|
        {
          id: rand(1..10000),
          name: "Related Item #{n}",
          score: rand * 100
        }
      end
    }
  end

  def get_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0 # MB
  end

  def format_number(num)
    num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def format_bytes(bytes)
    if bytes < 1024
      "#{bytes} B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(2)} KB"
    else
      "#{(bytes / 1024.0 / 1024.0).round(2)} MB"
    end
  end

  def format_mb(mb)
    "#{mb.round(2)} MB"
  end

  def cleanup_test_file(file)
    File.delete(file) if File.exist?(file)
  end

  def print_summary(results)
    puts "\n" + "=" * 70
    puts "Summary: JSON to XML Conversion Performance (Yajl)"
    puts "=" * 70
    puts
    puts "Records | JSON Gen | Convert | Total | Speed | Memory"
    puts "-" * 70

    results.each do |r|
      puts sprintf("%8s | %7.2fs | %6.2fs | %5.2fs | %7s/s | %6s",
        format_number(r[:size]),
        r[:json_time],
        r[:convert_time],
        r[:total_time],
        format_number(r[:records_per_sec]),
        format_mb(r[:memory_peak])
      )
    end

    puts "\n" + "=" * 70
    puts "Key Takeaways:"
    puts "  • Yajl provides streaming JSON parsing with minimal memory overhead"
    puts "  • Memory usage remains constant regardless of dataset size"
    puts "  • Perfect for processing huge JSON files (100K+ records)"
    puts "  • Parsing speed: ~#{results.last[:records_per_sec].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} records/sec"
    puts "  • Throughput: ~#{results.last[:throughput_mb]} MB/sec"
    puts "=" * 70
  end
end
