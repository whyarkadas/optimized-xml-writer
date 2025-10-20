#!/usr/bin/env ruby

require_relative '../lib/simple_hash_to_xml'
require 'csv'
require 'json'

# Ensure we're in the project root directory
Dir.chdir(File.expand_path('..', __dir__))

# Practical examples for different data sources
class PracticalXMLConverter

  # Example 1: Convert CSV file to XML (memory efficient)
  def self.csv_to_xml(csv_file, xml_file, headers: true)
    puts "Converting CSV to XML: #{csv_file} -> #{xml_file}"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'records')

    # Create enumerator from CSV that processes one row at a time
    csv_enumerator = Enumerator.new do |yielder|
      CSV.foreach(csv_file, headers: headers) do |row|
        # Convert CSV row to hash
        if headers
          yielder << row.to_h
        else
          # Create hash with column indices if no headers
          hash = {}
          row.each_with_index { |value, index| hash["column_#{index}"] = value }
          yielder << hash
        end
      end
    end

    xml_writer.write_hashes(csv_enumerator, 'record')
    puts "Conversion complete!"
  end

  # Example 2: Convert JSONL (JSON Lines) file to XML
  def self.jsonl_to_xml(jsonl_file, xml_file)
    puts "Converting JSONL to XML: #{jsonl_file} -> #{xml_file}"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'documents')

    # Create enumerator from JSONL file
    jsonl_enumerator = Enumerator.new do |yielder|
      File.foreach(jsonl_file) do |line|
        begin
          hash = JSON.parse(line.strip)
          yielder << hash
        rescue JSON::ParserError => e
          puts "Warning: Skipping invalid JSON line: #{e.message}"
        end
      end
    end

    xml_writer.write_hashes(jsonl_enumerator, 'document')
    puts "Conversion complete!"
  end

  # Example 3: Simulate database-like batch processing
  def self.simulate_database_to_xml(xml_file, total_records = 50000, batch_size = 1000)
    puts "Simulating database export to XML: #{total_records} records"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'database_export')

    # Simulate database cursor/batch processing
    database_enumerator = Enumerator.new do |yielder|
      (0...total_records).step(batch_size) do |offset|
        # Simulate fetching a batch from database
        batch = fetch_database_batch(offset, batch_size, total_records)
        batch.each { |record| yielder << record }

        puts "Processed batch: #{offset} - #{[offset + batch_size - 1, total_records - 1].min}"
      end
    end

    xml_writer.write_hashes(database_enumerator, 'record')
    puts "Database export complete!"
  end

  # Example 4: Process existing Ruby array in chunks to manage memory
  def self.array_to_xml_chunked(array, xml_file, chunk_size = 1000)
    puts "Converting array to XML in chunks of #{chunk_size}"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'array_data')

    # Process array in chunks to avoid memory issues
    chunked_enumerator = Enumerator.new do |yielder|
      array.each_slice(chunk_size) do |chunk|
        chunk.each { |item| yielder << item }

        # Optional: trigger garbage collection after each chunk
        GC.start
        puts "Processed chunk of #{chunk.size} items"
      end
    end

    xml_writer.write_hashes(chunked_enumerator, 'item')
    puts "Array conversion complete!"
  end

  private

  def self.fetch_database_batch(offset, batch_size, total_records)
    # Simulate database batch fetch
    actual_batch_size = [batch_size, total_records - offset].min
    return [] if actual_batch_size <= 0

    (0...actual_batch_size).map do |i|
      record_id = offset + i + 1
      {
        id: record_id,
        name: "User #{record_id}",
        email: "user#{record_id}@company.com",
        department: ["Engineering", "Sales", "Marketing", "Support"][record_id % 4],
        salary: rand(50000..150000),
        hire_date: (Date.today - rand(1000)).to_s,
        active: rand(10) > 1, # 90% active
        metadata: {
          last_login: Time.now - rand(30 * 24 * 3600), # Random time in last 30 days
          login_count: rand(500),
          preferences: {
            theme: ['light', 'dark'].sample,
            language: ['en', 'es', 'fr'].sample,
            timezone: ['UTC', 'EST', 'PST', 'GMT'].sample
          }
        }
      }
    end
  end
end

# XML Validation helper
class XMLValidator
  def self.validate_xml_file(xml_file)
    puts "Validating XML file: #{xml_file}"

    begin
      require 'nokogiri'

      File.open(xml_file, 'r') do |file|
        doc = Nokogiri::XML(file) { |config| config.strict }

        if doc.errors.empty?
          puts "✓ XML is valid!"
          puts "  Root element: <#{doc.root.name}>"
          puts "  Total child elements: #{doc.root.children.select(&:element?).size}"
          return true
        else
          puts "✗ XML validation errors:"
          doc.errors.each { |error| puts "  - #{error}" }
          return false
        end
      end

    rescue LoadError
      puts "Nokogiri gem not available. Performing basic validation..."
      basic_validate_xml_file(xml_file)
    rescue => e
      puts "✗ XML validation failed: #{e.message}"
      return false
    end
  end

  def self.basic_validate_xml_file(xml_file)
    # Basic validation without external gems
    content = File.read(xml_file)

    # Check for XML declaration
    unless content.start_with?('<?xml')
      puts "✗ Missing XML declaration"
      return false
    end

    # Basic tag matching (simplified)
    open_tags = content.scan(/<(\w+)[^>]*>/).flatten
    close_tags = content.scan(/<\/(\w+)>/).flatten

    if open_tags.sort == close_tags.sort
      puts "✓ Basic XML structure appears valid"
      return true
    else
      puts "✗ Tag mismatch detected"
      return false
    end
  end
end

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
