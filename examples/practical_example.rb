#!/usr/bin/env ruby

require_relative '../lib/utilities/practical_xml_converter'
require_relative '../lib/utilities/xml_validator'
require 'yajl'

# Ensure we're in the project root directory
Dir.chdir(File.expand_path('..', __dir__))

# Demo examples
if __FILE__ == $0
  puts "=== Practical XML Conversion Examples ===\n"

  # Create sample JSONL file using Yajl for fast encoding
  puts "1. Creating huge JSONL file (100K records)..."
  File.open('data/sample_data.jsonl', 'w') do |f|
    encoder = Yajl::Encoder.new
    100_000.times do |i|
      data = {
        id: i + 1,
        title: "Document #{i + 1}",
        content: "This is the content of document #{i + 1} with more text to make it realistic",
        tags: ["tag#{rand(10)}", "category#{rand(5)}", "type#{rand(3)}"],
        metadata: {
          created: Time.now.to_s,
          author: "Author #{rand(100)}",
          views: rand(10000),
          likes: rand(1000),
          comments: rand(100)
        },
        nested_data: {
          level1: { level2: { level3: "deep value #{i}" } },
          array_data: (1..5).map { |n| { index: n, value: rand(1000) } }
        }
      }
      f.puts encoder.encode(data)
    end
  end
  puts "   Created 100,000 JSON records"

  puts "\n=== Running Conversions ===\n"

  # Example 1: JSONL to XML
  PracticalXMLConverter.jsonl_to_xml('data/sample_data.jsonl', 'output/from_jsonl.xml')
  XMLValidator.validate_xml_file('output/from_jsonl.xml')

  puts "\n" + "="*50 + "\n"

  # Example 2: Process existing array
  large_array = Array.new(2000) do |i|
    {
      index: i,
      value: "Item #{i}",
      random_data: rand(1000),
      nested: { level: rand(5), score: rand(100) }
    }
  end

  PracticalXMLConverter.array_to_xml_chunked(large_array, 'output/from_array.xml', 200)
  XMLValidator.validate_xml_file('output/from_array.xml')

  puts "\n=== Summary ===\n"
  puts "Generated files:"
  ['output/from_jsonl.xml', 'output/from_array.xml'].each do |file|
    if File.exist?(file)
      size_kb = (File.size(file) / 1024.0).round(2)
      filename = File.basename(file)
      puts "  #{filename} (#{size_kb} KB)"
    end
  end

  puts "\nAll files are memory-efficiently generated and valid XML!"
end
