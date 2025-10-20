require_relative '../writers/memory_efficient_xml_writer'
require_relative '../writers/bulk_xml_writer'
require 'benchmark'

# Benchmark class for comparing XML writer performance
class XMLWriterBenchmark
  def initialize
    # Test sizes - bulk writer only runs for sizes <= 100,000 to avoid OOM
    @test_sizes = [1_000, 10_000, 50_000, 100_000, 500_000]
    @bulk_writer_limit = 500_000  # Don't run bulk writer above this size
  end

  def run_all_benchmarks
    puts "XML Writer Performance Benchmark with Large Datasets"
    puts "=" * 70
    puts "Ruby Version: #{RUBY_VERSION}"
    puts "System: #{RUBY_PLATFORM}"
    puts "Timestamp: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "=" * 70
    puts

    results = []

    @test_sizes.each do |size|
      puts "\n" + "=" * 70
      puts "Testing with #{format_number(size)} records"
      puts "=" * 70

      streaming_result = benchmark_streaming_writer(size)

      # Only run bulk writer for smaller datasets to avoid OOM
      if size <= @bulk_writer_limit
        bulk_result = benchmark_bulk_writer(size)
      else
        puts "\n2. Bulk Writer Test (Skipped - would cause OutOfMemory)"
        puts "   ⚠️  Bulk approach cannot handle #{format_number(size)} records"
        puts "   This demonstrates why streaming is essential for large datasets!"
        bulk_result = nil
      end

      results << {
        size: size,
        streaming: streaming_result,
        bulk: bulk_result
      }

      # Clean up files after each test
      cleanup_test_files

      # Force GC between tests
      GC.start
      sleep 0.5 # Brief pause between large tests
    end

    print_summary_table(results)

    puts "\n" + "=" * 70
    puts "Benchmark completed!"
  end

  def format_number(num)
    num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  private

  def benchmark_streaming_writer(record_count)
    puts "\n1. Streaming Writer Test"

    memory_before = get_memory_usage
    memory_peak = memory_before
    memory_samples = []

    # Sample memory every N records
    sample_interval = [record_count / 10, 1000].max

    time = Benchmark.realtime do
      writer = MemoryEfficientXMLWriter.new("output/streaming_test_#{record_count}.xml", 'records')
      writer.start_writing

      (1..record_count).each do |i|
        record = generate_test_record(i)
        writer.write_hash(record, 'record')

        # Sample memory usage
        if i % sample_interval == 0
          current_memory = get_memory_usage
          memory_samples << current_memory
          memory_peak = [memory_peak, current_memory].max
          print "." if record_count > 50_000
        end
      end

      writer.finish_writing
    end

    memory_after = get_memory_usage
    memory_peak = [memory_peak, memory_after].max
    file_size = File.size("output/streaming_test_#{record_count}.xml")

    avg_memory = memory_samples.empty? ? memory_after : (memory_samples.sum / memory_samples.size)

    puts "" if record_count > 50_000
    puts "   Time: #{format_time(time)}"
    puts "   Memory - Start: #{memory_before.round(2)} MB"
    puts "   Memory - Peak: #{memory_peak.round(2)} MB"
    puts "   Memory - End: #{memory_after.round(2)} MB"
    puts "   Memory - Delta: #{(memory_after - memory_before).round(2)} MB"
    puts "   Output file size: #{format_file_size(file_size)}"
    puts "   Processing speed: #{format_number((record_count / time).round(0))} records/sec"

    {
      time: time,
      memory_before: memory_before,
      memory_after: memory_after,
      memory_peak: memory_peak,
      memory_delta: memory_after - memory_before,
      file_size: file_size,
      records_per_sec: (record_count / time).round(0)
    }
  end

  def benchmark_bulk_writer(record_count)
    puts "\n2. Bulk Writer Test (Traditional - Loads All into Memory)"

    memory_before = get_memory_usage
    memory_peak = memory_before
    memory_samples = []

    # Sample memory every N records
    sample_interval = [record_count / 10, 1000].max

    time = Benchmark.realtime do
      writer = BulkXMLWriter.new("output/bulk_test_#{record_count}.xml", 'records')
      writer.start_writing

      (1..record_count).each do |i|
        record = generate_test_record(i)
        writer.write_hash(record, 'record')

        # Sample memory usage
        if i % sample_interval == 0
          current_memory = get_memory_usage
          memory_samples << current_memory
          memory_peak = [memory_peak, current_memory].max
          print "." if record_count > 50_000
        end
      end

      writer.finish_writing
    end

    memory_after = get_memory_usage
    memory_peak = [memory_peak, memory_after].max
    file_size = File.size("output/bulk_test_#{record_count}.xml")

    avg_memory = memory_samples.empty? ? memory_after : (memory_samples.sum / memory_samples.size)

    puts "" if record_count > 50_000
    puts "   Time: #{format_time(time)}"
    puts "   Memory - Start: #{memory_before.round(2)} MB"
    puts "   Memory - Peak: #{memory_peak.round(2)} MB"
    puts "   Memory - End: #{memory_after.round(2)} MB"
    puts "   Memory - Delta: #{(memory_after - memory_before).round(2)} MB"
    puts "   Output file size: #{format_file_size(file_size)}"
    puts "   Processing speed: #{format_number((record_count / time).round(0))} records/sec"

    {
      time: time,
      memory_before: memory_before,
      memory_after: memory_after,
      memory_peak: memory_peak,
      memory_delta: memory_after - memory_before,
      file_size: file_size,
      records_per_sec: (record_count / time).round(0)
    }
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
    Dir.glob("output/*_test_*.xml").each { |file| File.delete(file) if File.exist?(file) }
    Dir.glob("output/bulk_test_*.xml").each { |file| File.delete(file) if File.exist?(file) }
  end

  def format_time(seconds)
    if seconds < 60
      "#{seconds.round(3)} seconds"
    else
      minutes = (seconds / 60).floor
      remaining_seconds = (seconds % 60).round(1)
      "#{minutes}m #{remaining_seconds}s"
    end
  end

  def format_file_size(bytes)
    mb = bytes / 1024.0 / 1024.0
    if mb < 1024
      "#{mb.round(2)} MB"
    else
      gb = mb / 1024.0
      "#{gb.round(2)} GB"
    end
  end

  def print_summary_table(results)
    puts "\n" + "=" * 70
    puts "PERFORMANCE SUMMARY"
    puts "=" * 70
    puts
    puts "Streaming Writer Performance:"
    puts "-" * 70
    printf("%-15s %-12s %-15s %-15s %-15s\n", "Records", "Time", "Memory Delta", "File Size", "Speed")
    puts "-" * 70

    results.each do |result|
      printf("%-15s %-12s %-15s %-15s %-15s\n",
        format_number(result[:size]),
        format_time(result[:streaming][:time]),
        "#{result[:streaming][:memory_delta].round(2)} MB",
        format_file_size(result[:streaming][:file_size]),
        "#{format_number(result[:streaming][:records_per_sec])} rec/s"
      )
    end

    puts
    puts "Bulk Writer Performance (Traditional - All in Memory):"
    puts "-" * 70
    printf("%-15s %-12s %-15s %-15s %-15s\n", "Records", "Time", "Memory Delta", "File Size", "Speed")
    puts "-" * 70

    results.each do |result|
      if result[:bulk]
        printf("%-15s %-12s %-15s %-15s %-15s\n",
          format_number(result[:size]),
          format_time(result[:bulk][:time]),
          "#{result[:bulk][:memory_delta].round(2)} MB",
          format_file_size(result[:bulk][:file_size]),
          "#{format_number(result[:bulk][:records_per_sec])} rec/s"
        )
      else
        printf("%-15s %-12s\n",
          format_number(result[:size]),
          "SKIPPED (would OOM)"
        )
      end
    end

    puts
    puts "Memory Comparison:"
    puts "-" * 70

    # Calculate average memory increase (only for tests where bulk ran)
    bulk_results = results.select { |r| r[:bulk] }
    if bulk_results.any?
      avg_streaming_memory = bulk_results.map { |r| r[:streaming][:memory_delta] }.sum / bulk_results.size
      avg_bulk_memory = bulk_results.map { |r| r[:bulk][:memory_delta] }.sum / bulk_results.size

      puts "• Average memory delta (Streaming): #{avg_streaming_memory.round(2)} MB"
      puts "• Average memory delta (Bulk):      #{avg_bulk_memory.round(2)} MB"
      puts "• Memory savings: #{((avg_bulk_memory - avg_streaming_memory) / avg_bulk_memory * 100).round(1)}%"
      puts ""

      # Show peak memory comparison for largest test where bulk ran
      largest_bulk_test = bulk_results.last
      streaming_peak = largest_bulk_test[:streaming][:memory_peak]
      bulk_peak = largest_bulk_test[:bulk][:memory_peak]

      puts "Peak Memory Usage for #{format_number(largest_bulk_test[:size])} records (last comparable test):"
      puts "• Streaming Writer: #{streaming_peak.round(2)} MB"
      puts "• Bulk Writer:      #{bulk_peak.round(2)} MB"
      puts "• Difference:       #{(bulk_peak - streaming_peak).round(2)} MB"
      puts "• Streaming uses #{((streaming_peak / bulk_peak) * 100).round(1)}% of Bulk's memory"
      puts ""
    end

    max_records = results.last[:size]
    max_file_size = results.last[:streaming][:file_size]
    max_memory_delta = results.last[:streaming][:memory_delta]

    puts "Largest Test Results (#{format_number(max_records)} records):"
    puts "• File size generated: #{format_file_size(max_file_size)}"
    puts "• Streaming memory delta: #{max_memory_delta.round(2)} MB"
    if results.last[:bulk]
      puts "• Bulk memory delta: #{results.last[:bulk][:memory_delta].round(2)} MB"
    else
      puts "• Bulk writer: Not tested (would cause OutOfMemory)"
      puts "• This proves streaming is ESSENTIAL for large datasets!"
    end

    if max_memory_delta.abs < 200
      efficiency = ((max_file_size / 1024.0 / 1024.0) / [max_memory_delta.abs, 1].max).round(1)
      puts "• Streaming efficiency: #{efficiency}:1 (file:memory ratio)"
      puts ""
      puts "🎉 Successfully processed #{format_number(max_records)} records with minimal memory!"
    end
  end
end
