require_relative '../writers/memory_efficient_xml_writer'
require 'json'

# Practical examples for different data sources
class PracticalXMLConverter

  # Example 1: Convert JSONL (JSON Lines) file to XML
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

  # Example 2: Process existing Ruby array in chunks to manage memory
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
end
