require_relative '../writers/batch_xml_writer'
require 'time'

# Memory usage demonstration class
class MemoryUsageDemo
  def demonstrate_memory_efficiency
    puts "\n" + "=" * 70
    puts "EXTREME SCALE MEMORY EFFICIENCY TEST"
    puts "=" * 70

    test_size = 100_000
    puts "\nGenerating #{test_size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} complex records..."
    puts "Traditional approach would consume 2-4 GB of memory."
    puts "Watch how streaming keeps memory usage minimal!\n"

    initial_memory = get_memory_usage
    puts "Initial memory: #{initial_memory.round(2)} MB"
    puts ""

    writer = BatchXMLWriter.new('output/memory_demo.xml', 'large_dataset', 500)
    writer.start_writing

    start_time = Time.now
    (1..test_size).each do |i|
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

      if i % 10_000 == 0
        current_memory = get_memory_usage
        elapsed = Time.now - start_time
        rate = (i / elapsed).round(0)
        puts "Processed #{i.to_s.rjust(7)} records | Memory: #{current_memory.round(2)} MB | Δ: #{(current_memory - initial_memory).round(2).to_s.rjust(6)} MB | Rate: #{rate.to_s.rjust(6)} rec/s"
      end
    end

    writer.finish_writing

    final_memory = get_memory_usage
    file_size = File.size('output/memory_demo.xml')
    total_time = Time.now - start_time

    puts "\n" + "-" * 70
    puts "FINAL RESULTS:"
    puts "-" * 70
    puts "Records processed:    #{test_size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "Processing time:      #{total_time.round(2)} seconds"
    puts "Average speed:        #{(test_size / total_time).round(0).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} records/second"
    puts ""
    puts "Initial memory:       #{initial_memory.round(2)} MB"
    puts "Final memory:         #{final_memory.round(2)} MB"
    puts "Memory increase:      #{(final_memory - initial_memory).round(2)} MB"
    puts ""
    puts "Output file size:     #{(file_size / 1024.0 / 1024.0).round(2)} MB"

    if (final_memory - initial_memory) > 0
      efficiency = (file_size / 1024.0 / 1024.0 / (final_memory - initial_memory)).round(1)
      puts "Memory efficiency:    #{efficiency}:1 (file:memory ratio)"
    end

    puts ""
    puts "💡 Key Insight: Processed #{(file_size / 1024.0 / 1024.0).round(0)}MB of data"
    puts "   using only #{(final_memory - initial_memory).abs.round(0)}MB additional memory!"

    # Cleanup
    File.delete('output/memory_demo.xml') if File.exist?('output/memory_demo.xml')
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
