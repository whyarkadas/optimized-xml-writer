#!/usr/bin/env ruby

require 'nokogiri'

# Traditional bulk writer - loads everything into memory before writing
# This is ONLY for benchmark comparison purposes
# DO NOT use this for production - use MemoryEfficientXMLWriter instead!
# Uses Nokogiri for XML generation
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
    # Write everything at once at the end using Nokogiri
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.send(@root_element_name.to_sym) do
        @records.each do |record|
          build_element(xml, record[:element_name], record[:hash])
        end
      end
    end

    File.write(@file_path, builder.to_xml)
    @records.clear
  end

  private

  # Build XML element using Nokogiri's builder (same as MemoryEfficientXMLWriter)
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
