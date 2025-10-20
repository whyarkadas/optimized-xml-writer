#!/usr/bin/env ruby

require_relative 'memory_efficient_xml_writer'
require 'benchmark'

# Benchmark script to demonstrate memory efficiency and performance
class XMLWriterBenchmark
  def initialize
    @test_sizes = [1_000, 10_000, 50_000]
  end

  def run_all_benchmarks
    puts "XML Writer Performance Benchmark"
    puts "=" * 50
    puts "Ruby Version: #{RUBY_VERSION}"
    puts "System: #{RUBY_PLATFORM}"
    puts

    @test_sizes.each do |size|
      puts "\n" + "-" * 30
      puts "Testing with #{size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} records"
      puts "-" * 30

      benchmark_streaming_writer(size)
      benchmark_batch_writer(size)

      # Clean up files after each test
      cleanup_test_files
    end

    puts "\n" + "=" * 50
    puts "Benchmark completed!"
  end

  private

  def benchmark_streaming_writer(record_count)
    puts "\n1. Streaming Writer Test"

    memory_before = get_memory_usage

    time = Benchmark.realtime do
      writer = MemoryEfficientXMLWriter.new("streaming_test_#{record_count}.xml", 'records')
      writer.start_document

      (1..record_count).each do |i|
        record = generate_test_record(i)
        writer.write_hash(record, 'record')
      end

      writer.finish_document
    end

    memory_after = get_memory_usage
    file_size = File.size("streaming_test_#{record_count}.xml")

    puts "   Time: #{time.round(3)} seconds"
    puts "   Memory used: #{(memory_after - memory_before).round(2)} MB"
    puts "   Output file size: #{(file_size / 1024.0 / 1024.0).round(2)} MB"
    puts "   Records/second: #{(record_count / time).round(0)}"
  end

  def benchmark_batch_writer(record_count)
    puts "\n2. Batch Writer Test (batch_size: 1000)"

    memory_before = get_memory_usage

    time = Benchmark.realtime do
      writer = BatchXMLWriter.new("batch_test_#{record_count}.xml", 'records', 1000)
      writer.start_document

      (1..record_count).each do |i|
        record = generate_test_record(i)
        writer.add_to_batch(record, 'record')
      end

      writer.finish_document
    end

    memory_after = get_memory_usage
    file_size = File.size("batch_test_#{record_count}.xml")

    puts "   Time: #{time.round(3)} seconds"
    puts "   Memory used: #{(memory_after - memory_before).round(2)} MB"
    puts "   Output file size: #{(file_size / 1024.0 / 1024.0).round(2)} MB"
    puts "   Records/second: #{(record_count / time).round(0)}"
  end

  def generate_test_record(id)
    {
      id: id,
      name: "Test User #{id}",
      email: "user#{id}@example.com",
      created_at: Time.now.iso8601,
      profile: {
        age: rand(18..80),
        city: ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix"].sample,
        score: rand(0..100),
        active: [true, false].sample
      },
      metadata: {
        last_login: (Time.now - rand(86400)).iso8601,
        session_count: rand(1..1000),
        preferences: {
          theme: ["light", "dark"].sample,
          language: ["en", "es", "fr", "de"].sample,
          notifications: {
            email: [true, false].sample,
            sms: [true, false].sample,
            push: [true, false].sample
          }
        }
      },
      tags: Array.new(rand(3..8)) { "tag_#{rand(1..50)}" },
      orders: Array.new(rand(0..5)) do |i|
        {
          order_id: "ORD_#{id}_#{i}",
          amount: (rand * 1000).round(2),
          date: (Date.today - rand(365)).to_s,
          status: ["pending", "completed", "cancelled"].sample
        }
      end
    }
  end

  def get_memory_usage
    # Get RSS (Resident Set Size) in MB
    if RUBY_PLATFORM =~ /darwin/
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    elsif RUBY_PLATFORM =~ /linux/
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    else
      # Fallback - return 0 if we can't determine memory usage
      0
    end
  end

  def cleanup_test_files
    Dir.glob("*_test_*.xml").each { |file| File.delete(file) if File.exist?(file) }
  end
end

# Memory usage demonstration
class MemoryUsageDemo
  def demonstrate_memory_efficiency
    puts "\nMemory Usage Demonstration"
    puts "=" * 30

    puts "\nGenerating 25,000 complex records..."
    puts "This would typically consume several GB if done in-memory."
    puts "Watch the memory usage stay minimal with streaming approach.\n"

    initial_memory = get_memory_usage
    puts "Initial memory: #{initial_memory.round(2)} MB"

    writer = BatchXMLWriter.new('memory_demo.xml', 'large_dataset', 500)
    writer.start_document

    (1..25_000).each do |i|
      # Create a fairly complex record
      complex_record = {
        id: i,
        timestamp: Time.now.iso8601,
        user_data: {
          name: "User #{i}",
          email: "user#{i}@example.com",
          profile: {
            bio: "This is a longer bio text for user #{i} that contains more data to make the record larger and more realistic for testing memory usage patterns.",
            settings: {
              theme: "dark",
              language: "en",
              timezone: "UTC",
              features: ["feature_#{rand(1..10)}", "feature_#{rand(11..20)}", "feature_#{rand(21..30)}"]
            }
          }
        },
        analytics: {
          page_views: rand(1000..10000),
          session_duration: rand(60..3600),
          bounce_rate: rand(0.1..0.9).round(3),
          conversion_events: Array.new(rand(1..10)) do |j|
            {
              event_id: "evt_#{i}_#{j}",
              event_type: ["click", "view", "purchase", "signup"].sample,
              timestamp: (Time.now - rand(86400)).iso8601,
              value: rand(1..100)
            }
          end
        }
      }

      writer.add_to_batch(complex_record, 'record')

      if i % 2500 == 0
        current_memory = get_memory_usage
        puts "Processed #{i.to_s.rjust(6)} records | Memory: #{current_memory.round(2)} MB | Δ: +#{(current_memory - initial_memory).round(2)} MB"
      end
    end

    writer.finish_document

    final_memory = get_memory_usage
    file_size = File.size('memory_demo.xml')

    puts "\nFinal Results:"
    puts "- Records processed: 25,000"
    puts "- Final memory usage: #{final_memory.round(2)} MB"
    puts "- Total memory increase: #{(final_memory - initial_memory).round(2)} MB"
    puts "- Output file size: #{(file_size / 1024.0 / 1024.0).round(2)} MB"
    puts "- Memory efficiency ratio: #{(file_size / 1024.0 / 1024.0 / (final_memory - initial_memory)).round(1)}:1"

    # Cleanup
    File.delete('memory_demo.xml') if File.exist?('memory_demo.xml')
  end

  private

  def get_memory_usage
    if RUBY_PLATFORM =~ /darwin/
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    elsif RUBY_PLATFORM =~ /linux/
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
    else
      0
    end
  end
end

# Run benchmarks if this file is executed directly
if __FILE__ == $0
  benchmark = XMLWriterBenchmark.new
  benchmark.run_all_benchmarks

  memory_demo = MemoryUsageDemo.new
  memory_demo.demonstrate_memory_efficiency
end
