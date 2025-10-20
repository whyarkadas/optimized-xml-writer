#!/usr/bin/env ruby

require 'rexml/document'
require 'rexml/formatters/pretty'

class MemoryEfficientXMLWriter
  def initialize(file_path, root_element_name = 'data')
    @file_path = file_path
    @root_element_name = root_element_name
    @file = nil
  end

  # Start writing XML - opens file and writes XML declaration and root element
  def start_writing
    @file = File.open(@file_path, 'w')
    @file.write('<?xml version="1.0" encoding="UTF-8"?>')
    @file.write("\n<#{@root_element_name}>\n")
  end

  # Write a single hash as XML element
  def write_hash(hash, element_name = 'item')
    return unless @file

    @file.write("  <#{element_name}>\n")
    write_hash_content(hash, 2)
    @file.write("  </#{element_name}>\n")
    @file.flush # Ensure data is written to disk immediately
  end

  # Write multiple hashes iteratively (memory efficient)
  def write_hashes(hash_array, element_name = 'item')
    hash_array.each do |hash|
      write_hash(hash, element_name)
    end
  end

  # Write hashes from an enumerator or any iterable (most memory efficient)
  def write_from_enumerator(enumerator, element_name = 'item')
    enumerator.each do |hash|
      write_hash(hash, element_name)
    end
  end

  # Finish writing XML - closes root element and file
  def finish_writing
    return unless @file

    @file.write("</#{@root_element_name}>\n")
    @file.close
    @file = nil
  end

  # Complete process in one method with block
  def write_xml
    start_writing
    yield(self) if block_given?
    finish_writing
  end

  private

  # Recursively write hash content with proper indentation
  def write_hash_content(hash, indent_level = 0)
    indent = '  ' * indent_level

    hash.each do |key, value|
      case value
      when Hash
        @file.write("#{indent}<#{escape_xml_name(key)}>\n")
        write_hash_content(value, indent_level + 1)
        @file.write("#{indent}</#{escape_xml_name(key)}>\n")
      when Array
        value.each do |item|
          if item.is_a?(Hash)
            @file.write("#{indent}<#{escape_xml_name(key)}>\n")
            write_hash_content(item, indent_level + 1)
            @file.write("#{indent}</#{escape_xml_name(key)}>\n")
          else
            @file.write("#{indent}<#{escape_xml_name(key)}>#{escape_xml_content(item.to_s)}</#{escape_xml_name(key)}>\n")
          end
        end
      else
        @file.write("#{indent}<#{escape_xml_name(key)}>#{escape_xml_content(value.to_s)}</#{escape_xml_name(key)}>\n")
      end
    end
  end

  # Escape XML element names (replace invalid characters)
  def escape_xml_name(name)
    name.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
  end

  # Escape XML content
  def escape_xml_content(content)
    content.gsub('&', '&amp;')
           .gsub('<', '&lt;')
           .gsub('>', '&gt;')
           .gsub('"', '&quot;')
           .gsub("'", '&apos;')
  end
end

# Traditional bulk writer - loads everything into memory (for comparison)
class BulkXMLWriter
  def initialize(file_path, root_element_name = 'data')
    @file_path = file_path
    @root_element_name = root_element_name
    @records = [] # Stores all records in memory!
  end

  def start_writing
    @records = []
  end

  def write_hash(hash, element_name = 'item')
    # Store in memory instead of writing immediately
    @records << { hash: hash, element_name: element_name }
  end

  def add_to_batch(hash, element_name = 'item')
    write_hash(hash, element_name)
  end

  def finish_writing
    # Write everything at once at the end
    File.open(@file_path, 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write("\n<#{@root_element_name}>\n")

      @records.each do |record|
        xml_string = hash_to_xml_string(record[:hash], record[:element_name], 1)
        file.write(xml_string)
      end

      file.write("</#{@root_element_name}>\n")
    end

    @records.clear
  end

  private

  def hash_to_xml_string(hash, element_name, indent_level = 0)
    indent = '  ' * indent_level
    lines = ["#{indent}<#{element_name}>"]

    hash.each do |key, value|
      case value
      when Hash
        lines << hash_to_xml_string(value, escape_xml_name(key.to_s), indent_level + 1)
      when Array
        value.each do |item|
          if item.is_a?(Hash)
            lines << hash_to_xml_string(item, escape_xml_name(key.to_s), indent_level + 1)
          else
            lines << "#{indent}  <#{escape_xml_name(key.to_s)}>#{escape_xml_content(item.to_s)}</#{escape_xml_name(key.to_s)}>"
          end
        end
      else
        lines << "#{indent}  <#{escape_xml_name(key.to_s)}>#{escape_xml_content(value.to_s)}</#{escape_xml_name(key.to_s)}>"
      end
    end

    lines << "#{indent}</#{element_name}>"
    lines.join("\n") + "\n"
  end

  def escape_xml_name(name)
    name.gsub(/[^a-zA-Z0-9_-]/, '_').gsub(/^[^a-zA-Z_]/, '_')
  end

  def escape_xml_content(content)
    content.gsub('&', '&amp;')
           .gsub('<', '&lt;')
           .gsub('>', '&gt;')
           .gsub('"', '&quot;')
           .gsub("'", '&apos;')
  end
end

# Enhanced version for very large datasets with batch processing
class BatchXMLWriter < MemoryEfficientXMLWriter
  def initialize(file_path, root_element_name = 'data', batch_size = 1000)
    super(file_path, root_element_name)
    @batch_size = batch_size
    @current_batch = []
  end

  def add_to_batch(hash, element_name = 'item')
    @current_batch << { hash: hash, element_name: element_name }

    if @current_batch.size >= @batch_size
      flush_batch
    end
  end

  def flush_batch
    return if @current_batch.empty?

    @current_batch.each do |item|
      write_hash(item[:hash], item[:element_name])
    end

    @current_batch.clear
    GC.start # Force garbage collection to free memory
  end

  def finish_writing
    flush_batch # Write any remaining items
    super
  end
end

# Alternative streaming approach using REXML (slightly more memory but cleaner XML)
class REXMLStreamingWriter
  def initialize(file_path, root_element_name = 'data')
    @file_path = file_path
    @root_element_name = root_element_name
  end

  def write_hashes(hash_array, element_name = 'item')
    File.open(@file_path, 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write("\n<#{@root_element_name}>\n")

      hash_array.each do |hash|
        element = hash_to_xml_element(hash, element_name)
        formatter = REXML::Formatters::Pretty.new(2)
        output = ""
        formatter.write(element, output)
        file.write("  #{output.strip}\n")
        file.flush
      end

      file.write("</#{@root_element_name}>\n")
    end
  end

  private

  def hash_to_xml_element(hash, element_name)
    element = REXML::Element.new(element_name)
    add_hash_to_element(element, hash)
    element
  end

  def add_hash_to_element(parent, hash)
    hash.each do |key, value|
      case value
      when Hash
        child = parent.add_element(key.to_s)
        add_hash_to_element(child, value)
      when Array
        value.each do |item|
          if item.is_a?(Hash)
            child = parent.add_element(key.to_s)
            add_hash_to_element(child, item)
          else
            child = parent.add_element(key.to_s)
            child.text = item.to_s
          end
        end
      else
        child = parent.add_element(key.to_s)
        child.text = value.to_s
      end
    end
  end
end

# Example usage and demonstration
if __FILE__ == $0
  # Sample hash data (simulating a large dataset)
  def generate_sample_data(count = 1000)
    (1..count).map do |i|
      {
        id: i,
        name: "Record #{i}",
        email: "user#{i}@example.com",
        created_at: Time.now - rand(365 * 24 * 3600), # Random time in past year
        metadata: {
          source: "api",
          version: "1.#{rand(10)}",
          tags: ["tag#{rand(5)}", "category#{rand(3)}"]
        },
        settings: {
          active: [true, false].sample,
          priority: rand(1..10),
          config: {
            theme: ["dark", "light"].sample,
            notifications: [true, false].sample
          }
        }
      }
    end
  end

  puts "Memory Efficient XML Writer Demo"
  puts "=" * 40

  # Method 1: Using custom streaming writer (most memory efficient)
  puts "\n1. Writing with custom streaming writer..."

  writer = MemoryEfficientXMLWriter.new('./output_streaming.xml', 'records')

  # Using the block approach
  writer.write_xml do |w|
    # Simulate processing huge dataset in chunks
    (1..5).each do |chunk|
      puts "  Processing chunk #{chunk}..."
      sample_data = generate_sample_data(200) # 200 records per chunk
      w.write_hashes(sample_data, 'record')
    end
  end

  puts "  ✓ Created output_streaming.xml (1000 records)"

  # Method 2: Using enumerator for ultimate memory efficiency
  puts "\n2. Writing with enumerator (ultimate memory efficiency)..."

  # Create an enumerator that generates data on-demand
  data_enumerator = Enumerator.new do |yielder|
    (1..1000).each do |i|
      yielder << {
        id: i,
        name: "Enumerator Record #{i}",
        timestamp: Time.now.to_i,
        data: "Some data for record #{i}"
      }
    end
  end

  writer2 = MemoryEfficientXMLWriter.new('./output_enumerator.xml', 'enumerator_records')
  writer2.start_writing
  writer2.write_from_enumerator(data_enumerator, 'record')
  writer2.finish_writing

  puts "  ✓ Created output_enumerator.xml (1000 records)"

  # Method 3: Using REXML streaming writer (cleaner XML output)
  puts "\n3. Writing with REXML streaming writer..."

  rexml_writer = REXMLStreamingWriter.new('./output_rexml.xml', 'rexml_records')
  sample_data = generate_sample_data(100) # Smaller dataset for demo
  rexml_writer.write_hashes(sample_data, 'record')

  puts "  ✓ Created output_rexml.xml (100 records)"

  # Show file sizes
  puts "\nGenerated files:"
  Dir.glob('./output_*.xml').each do |file|
    size = File.size(file)
    puts "  #{file}: #{size} bytes (#{(size / 1024.0).round(2)} KB)"
  end

  puts "\nAll XML files are valid and ready for use!"
  puts "\nFor huge datasets, use Method 1 or 2 for maximum memory efficiency."
end
