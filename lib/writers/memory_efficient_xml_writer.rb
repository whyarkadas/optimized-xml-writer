#!/usr/bin/env ruby

require 'nokogiri'

# Memory-efficient XML writer that streams data directly to file
# without loading entire dataset into memory
# Uses Nokogiri for XML generation and validation
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

  # Write a single hash as XML element using Nokogiri
  def write_hash(hash, element_name = 'item')
    return unless @file

    # Create XML element using Nokogiri
    builder = Nokogiri::XML::Builder.new do |xml|
      build_element(xml, element_name, hash)
    end

    # Extract just the element (without XML declaration)
    doc = Nokogiri::XML(builder.to_xml)
    element_xml = doc.root.to_xml(indent: 2)

    @file.write("  #{element_xml}\n")
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

  # Build XML element using Nokogiri's builder
  def build_element(xml, element_name, content)
    case content
    when Hash
      xml.send(sanitize_element_name(element_name)) do
        content.each do |key, value|
          build_element(xml, key.to_s, value)
        end
      end
    when Array
      content.each do |item|
        build_element(xml, element_name, item)
      end
    else
      xml.send(sanitize_element_name(element_name), content.to_s)
    end
  end

  # Sanitize XML element names to be valid
  def sanitize_element_name(name)
    # Ensure element name starts with letter or underscore
    sanitized = name.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
    sanitized = "_#{sanitized}" if sanitized =~ /^[^a-zA-Z_]/
    sanitized
  end
end
