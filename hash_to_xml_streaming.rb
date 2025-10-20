#!/usr/bin/env ruby

require 'nokogiri'
require 'json'

class StreamingXMLWriter
  def initialize(output_file, root_element = 'data')
    @output_file = output_file
    @root_element = root_element
    @file = nil
    @xml_writer = nil
  end

  def open
    @file = File.open(@output_file, 'w')
    @xml_writer = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      # We'll manually control the structure
    end

    # Write XML declaration and root opening tag
    @file.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    @file.write("<#{@root_element}>\n")
  end

  def write_hash(hash, element_name = 'item')
    return unless @file

    # Start the item element
    @file.write("  <#{element_name}>\n")

    # Write each key-value pair
    hash.each do |key, value|
      write_element(key, value, 4) # 4 spaces indentation
    end

    # Close the item element
    @file.write("  </#{element_name}>\n")

    # Flush to ensure memory doesn't accumulate
    @file.flush
  end

  def close
    return unless @file

    # Write root closing tag
    @file.write("</#{@root_element}>\n")
    @file.close
    @file = nil
  end

  private

  def write_element(key, value, indent_level = 0)
    indent = ' ' * indent_level
    safe_key = escape_xml_element_name(key.to_s)

    case value
    when Hash
      @file.write("#{indent}<#{safe_key}>\n")
      value.each do |nested_key, nested_value|
        write_element(nested_key, nested_value, indent_level + 2)
      end
      @file.write("#{indent}</#{safe_key}>\n")
    when Array
      @file.write("#{indent}<#{safe_key}>\n")
      value.each_with_index do |item, index|
        write_element("item_#{index}", item, indent_level + 2)
      end
      @file.write("#{indent}</#{safe_key}>\n")
    else
      escaped_value = escape_xml_content(value.to_s)
      @file.write("#{indent}<#{safe_key}>#{escaped_value}</#{safe_key}>\n")
    end
  end

  def escape_xml_content(text)
    text.gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
        .gsub('"', '&quot;')
        .gsub("'", '&apos;')
  end

  def escape_xml_element_name(name)
    # Replace invalid XML element name characters
    name.gsub(/[^a-zA-Z0-9_-]/, '_')
        .gsub(/^[^a-zA-Z_]/, '_') # Ensure it starts with letter or underscore
  end
end

# Example usage with memory-efficient processing
class HashArrayToXML
  def self.process_large_dataset(input_data, output_file, batch_size: 1000)
    xml_writer = StreamingXMLWriter.new(output_file, 'records')

    begin
      xml_writer.open

      case input_data
      when String
        # If input_data is a file path
        process_from_file(xml_writer, input_data, batch_size)
      when Array
        # If input_data is already an array in memory
        process_from_array(xml_writer, input_data, batch_size)
      when Enumerator
        # If input_data is an enumerator (most memory efficient)
        process_from_enumerator(xml_writer, input_data, batch_size)
      else
        raise ArgumentError, "Unsupported input data type: #{input_data.class}"
      end

    ensure
      xml_writer.close
    end

    puts "XML file created successfully: #{output_file}"
  end

  private

  def self.process_from_file(xml_writer, file_path, batch_size)
    File.open(file_path, 'r') do |file|
      file.each_line.lazy.each_slice(batch_size) do |batch|
        batch.each do |line|
          begin
            hash_data = JSON.parse(line.strip)
            xml_writer.write_hash(hash_data, 'record')
          rescue JSON::ParserError => e
            puts "Skipping invalid JSON line: #{e.message}"
          end
        end

        # Optional: Add progress indicator
        puts "Processed batch of #{batch.size} records"

        # Force garbage collection periodically to free memory
        GC.start if rand(10) == 0
      end
    end
  end

  def self.process_from_array(xml_writer, array, batch_size)
    array.each_slice(batch_size) do |batch|
      batch.each do |hash_data|
        xml_writer.write_hash(hash_data, 'record')
      end

      puts "Processed batch of #{batch.size} records"
      GC.start if rand(10) == 0
    end
  end

  def self.process_from_enumerator(xml_writer, enumerator, batch_size)
    batch = []
    enumerator.each do |hash_data|
      batch << hash_data

      if batch.size >= batch_size
        batch.each { |data| xml_writer.write_hash(data, 'record') }
        puts "Processed batch of #{batch.size} records"
        batch.clear
        GC.start if rand(10) == 0
      end
    end

    # Process remaining items
    batch.each { |data| xml_writer.write_hash(data, 'record') } unless batch.empty?
  end
end

# Example 1: Processing from an array (less memory efficient but simple)
def example_array_processing
  puts "=== Example 1: Array Processing ==="

  # Sample data - in real scenario this would be huge
  sample_data = [
    { id: 1, name: "John Doe", email: "john@example.com", metadata: { age: 30, city: "NYC" } },
    { id: 2, name: "Jane Smith", email: "jane@example.com", metadata: { age: 25, city: "LA" } },
    { id: 3, name: "Bob Johnson", email: "bob@example.com", metadata: { age: 35, city: "Chicago" } }
  ]

  HashArrayToXML.process_large_dataset(sample_data, 'output_array.xml', batch_size: 2)
end

# Example 2: Processing with an enumerator (most memory efficient)
def example_enumerator_processing
  puts "\n=== Example 2: Enumerator Processing (Memory Efficient) ==="

  # Create an enumerator that generates data on-demand
  data_enumerator = Enumerator.new do |yielder|
    # Simulate reading from database, API, or large file
    1000.times do |i|
      yielder << {
        id: i + 1,
        name: "User #{i + 1}",
        email: "user#{i + 1}@example.com",
        timestamp: Time.now.to_i,
        data: {
          score: rand(100),
          level: rand(10),
          tags: ["tag#{rand(5)}", "category#{rand(3)}"]
        }
      }
    end
  end

  HashArrayToXML.process_large_dataset(data_enumerator, 'output_enumerator.xml', batch_size: 100)
end

# Example 3: Processing from JSONL file (streaming from disk)
def example_file_processing
  puts "\n=== Example 3: File Processing ==="

  # First, create a sample JSONL file
  File.open('sample_data.jsonl', 'w') do |f|
    10.times do |i|
      data = {
        id: i + 1,
        name: "Record #{i + 1}",
        details: {
          value: rand(1000),
          category: "cat_#{rand(5)}",
          active: [true, false].sample
        }
      }
      f.puts(JSON.generate(data))
    end
  end

  HashArrayToXML.process_large_dataset('sample_data.jsonl', 'output_file.xml', batch_size: 3)
end

# Run examples
if __FILE__ == $0
  example_array_processing
  example_enumerator_processing
  example_file_processing

  puts "\n=== Files created ==="
  puts "- output_array.xml"
  puts "- output_enumerator.xml"
  puts "- output_file.xml"
  puts "- sample_data.jsonl (sample input file)"
end
