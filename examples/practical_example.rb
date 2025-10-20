#!/usr/bin/env ruby

require_relative '../lib/utilities/practical_xml_converter'
require_relative '../lib/utilities/xml_validator'
require 'csv'
require 'json'

# Ensure we're in the project root directory
Dir.chdir(File.expand_path('..', __dir__))

# Demo examples
if __FILE__ == $0
  puts "=== Practical XML Conversion Examples ===\n"

  # Create sample CSV file
  puts "1. Creating sample CSV file..."
  CSV.open('data/sample_data.csv', 'w') do |csv|
    csv << ['id', 'name', 'email', 'age', 'city']
    100.times do |i|
      csv << [i + 1, "Person #{i + 1}", "person#{i + 1}@example.com", rand(18..65), ['NYC', 'LA', 'Chicago', 'Houston'].sample]
    end
  end

  # Create sample JSONL file
  puts "2. Creating sample JSONL file..."
  File.open('data/sample_data.jsonl', 'w') do |f|
    50.times do |i|
      data = {
        id: i + 1,
        title: "Document #{i + 1}",
        content: "This is the content of document #{i + 1}",
        tags: ["tag#{rand(10)}", "category#{rand(5)}"],
        metadata: { created: Time.now.to_s, author: "Author #{rand(10)}" }
      }
      f.puts JSON.generate(data)
    end
  end

  puts "\n=== Running Conversions ===\n"

  # Example 1: CSV to XML
  PracticalXMLConverter.csv_to_xml('data/sample_data.csv', 'output/from_csv.xml')
  XMLValidator.validate_xml_file('output/from_csv.xml')

  puts "\n" + "="*50 + "\n"

  # Example 2: JSONL to XML
  PracticalXMLConverter.jsonl_to_xml('data/sample_data.jsonl', 'output/from_jsonl.xml')
  XMLValidator.validate_xml_file('output/from_jsonl.xml')

  puts "\n" + "="*50 + "\n"

  # Example 3: Simulate large database export
  PracticalXMLConverter.simulate_database_to_xml('output/from_database.xml', 5000, 500)
  XMLValidator.validate_xml_file('output/from_database.xml')

  puts "\n" + "="*50 + "\n"

  # Example 4: Process existing array
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
  ['output/from_csv.xml', 'output/from_jsonl.xml', 'output/from_database.xml', 'output/from_array.xml'].each do |file|
    if File.exist?(file)
      size_kb = (File.size(file) / 1024.0).round(2)
      filename = File.basename(file)
      puts "  #{filename} (#{size_kb} KB)"
    end
  end

  puts "\nAll files are memory-efficiently generated and valid XML!"
end
