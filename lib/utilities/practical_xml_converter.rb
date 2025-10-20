require_relative '../writers/memory_efficient_xml_writer'
require 'csv'
require 'json'

# Practical examples for different data sources
class PracticalXMLConverter

  # Example 1: Convert CSV file to XML (memory efficient)
  def self.csv_to_xml(csv_file, xml_file, headers: true)
    puts "Converting CSV to XML: #{csv_file} -> #{xml_file}"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'records')
    xml_writer.start_writing

    # Process CSV row by row
    CSV.foreach(csv_file, headers: headers) do |row|
      # Convert CSV row to hash
      hash = headers ? row.to_h : row.each_with_index.to_h { |v, i| ["column_#{i}", v] }
      xml_writer.write_hash(hash, 'record')
    end

    xml_writer.finish_writing
    puts "Conversion complete!"
  end

  # Example 2: Convert JSONL (JSON Lines) file to XML
  def self.jsonl_to_xml(jsonl_file, xml_file)
    puts "Converting JSONL to XML: #{jsonl_file} -> #{xml_file}"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'documents')
    xml_writer.start_writing

    # Process JSONL file line by line
    File.foreach(jsonl_file) do |line|
      begin
        hash = JSON.parse(line.strip)
        xml_writer.write_hash(hash, 'document')
      rescue JSON::ParserError => e
        puts "Warning: Skipping invalid JSON line: #{e.message}"
      end
    end

    xml_writer.finish_writing
    puts "Conversion complete!"
  end

  # Example 3: Simulate database-like batch processing
  def self.simulate_database_to_xml(xml_file, total_records = 50000, batch_size = 1000)
    puts "Simulating database export to XML: #{total_records} records"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'database_export')
    xml_writer.start_writing

    # Simulate database cursor/batch processing
    (0...total_records).step(batch_size) do |offset|
      # Simulate fetching a batch from database
      batch = fetch_database_batch(offset, batch_size, total_records)
      batch.each { |record| xml_writer.write_hash(record, 'record') }

      puts "Processed batch: #{offset} - #{[offset + batch_size - 1, total_records - 1].min}"
    end

    xml_writer.finish_writing
    puts "Database export complete!"
  end

  # Example 4: Process existing Ruby array in chunks to manage memory
  def self.array_to_xml_chunked(array, xml_file, chunk_size = 1000)
    puts "Converting array to XML in chunks of #{chunk_size}"

    xml_writer = MemoryEfficientXMLWriter.new(xml_file, 'array_data')
    xml_writer.start_writing

    # Process array in chunks to avoid memory issues
    array.each_slice(chunk_size) do |chunk|
      chunk.each { |item| xml_writer.write_hash(item, 'item') }

      # Optional: trigger garbage collection after each chunk
      GC.start
      puts "Processed chunk of #{chunk.size} items"
    end

    xml_writer.finish_writing
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
