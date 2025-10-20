#!/usr/bin/env ruby

# Simple memory-efficient hash array to XML writer
class MemoryEfficientXMLWriter
  def initialize(filename, root_tag = 'data')
    @filename = filename
    @root_tag = root_tag
  end

  def write_hashes(hash_data_source, item_tag = 'item')
    File.open(@filename, 'w') do |file|
      # Write XML header and root opening tag
      file.write "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      file.write "<#{@root_tag}>\n"

      # Process data source (could be array, enumerator, or any enumerable)
      hash_data_source.each_with_index do |hash, index|
        write_hash_to_file(file, hash, item_tag)

        # Flush periodically to avoid memory buildup
        file.flush if (index + 1) % 100 == 0

        # Optional: Trigger garbage collection periodically for very large datasets
        GC.start if (index + 1) % 1000 == 0
      end

      # Write root closing tag
      file.write "</#{@root_tag}>\n"
    end
  end

  private

  def write_hash_to_file(file, hash, tag_name, indent = 2)
    spaces = ' ' * indent
    file.write "#{spaces}<#{tag_name}>\n"

    hash.each do |key, value|
      write_value_to_file(file, key, value, indent + 2)
    end

    file.write "#{spaces}</#{tag_name}>\n"
  end

  def write_value_to_file(file, key, value, indent)
    spaces = ' ' * indent
    safe_key = sanitize_tag_name(key.to_s)

    case value
    when Hash
      file.write "#{spaces}<#{safe_key}>\n"
      value.each do |nested_key, nested_value|
        write_value_to_file(file, nested_key, nested_value, indent + 2)
      end
      file.write "#{spaces}</#{safe_key}>\n"
    when Array
      file.write "#{spaces}<#{safe_key}>\n"
      value.each_with_index do |item, index|
        write_value_to_file(file, "item_#{index}", item, indent + 2)
      end
      file.write "#{spaces}</#{safe_key}>\n"
    else
      escaped_value = escape_xml(value.to_s)
      file.write "#{spaces}<#{safe_key}>#{escaped_value}</#{safe_key}>\n"
    end
  end

  def sanitize_tag_name(name)
    # Replace invalid characters with underscores
    name.gsub(/[^a-zA-Z0-9_-]/, '_').gsub(/^[^a-zA-Z_]/, '_')
  end

  def escape_xml(text)
    text.gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
        .gsub('"', '&quot;')
        .gsub("'", '&apos;')
  end
end

# Memory-efficient data generator (simulates reading from database/API)
def create_large_dataset_enumerator(size = 10000)
  Enumerator.new do |yielder|
    size.times do |i|
      # This generates one record at a time, never storing all in memory
      yielder << {
        id: i + 1,
        name: "Record #{i + 1}",
        email: "user#{i + 1}@example.com",
        created_at: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        metadata: {
          score: rand(1000),
          level: rand(50),
          active: [true, false].sample,
          tags: Array.new(rand(3) + 1) { "tag_#{rand(100)}" }
        },
        preferences: {
          theme: ['dark', 'light'].sample,
          notifications: rand(2) == 1,
          language: ['en', 'es', 'fr', 'de'].sample
        }
      }
    end
  end
end

# Example usage
if __FILE__ == $0
  puts "Creating memory-efficient XML from large hash dataset..."

  # Create a data source that generates 10,000 records without storing them all in memory
  large_dataset = create_large_dataset_enumerator(10000)

  # Write to XML file efficiently
  xml_writer = MemoryEfficientXMLWriter.new('large_output.xml', 'users')

  start_time = Time.now
  xml_writer.write_hashes(large_dataset, 'user')
  end_time = Time.now

  puts "XML file 'large_output.xml' created successfully!"
  puts "Processing time: #{(end_time - start_time).round(2)} seconds"
  puts "File size: #{File.size('large_output.xml')} bytes"

  # Show a sample of the generated XML
  puts "\nFirst few lines of the generated XML:"
  File.open('large_output.xml', 'r') do |file|
    10.times do
      line = file.gets
      break unless line
      puts line
    end
  end
end
