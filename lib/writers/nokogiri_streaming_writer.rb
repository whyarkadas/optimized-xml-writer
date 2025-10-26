#!/usr/bin/env ruby

require 'nokogiri'

# Alternative streaming approach using Nokogiri library with enhanced formatting
# Produces clean XML output with proper indentation by re-parsing
# Good for smaller to medium datasets where XML formatting is important
# Note: Uses extra parsing step for prettier output, resulting in higher memory usage
class NokogiriStreamingWriter
  def initialize(file_path, root_element_name = 'data')
    @file_path = file_path
    @root_element_name = root_element_name
  end

  def write_hashes(hash_array, element_name = 'item')
    File.open(@file_path, 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write("\n<#{@root_element_name}>\n")

      hash_array.each do |hash|
        # Create individual XML element using Nokogiri
        builder = Nokogiri::XML::Builder.new do |xml|
          build_element(xml, element_name, hash)
        end

        # Extract just the element with proper indentation
        doc = Nokogiri::XML(builder.to_xml)
        element_xml = doc.root.to_xml(indent: 2)

        # Add proper indentation for the root element
        indented_xml = element_xml.lines.map { |line| "  #{line}" }.join
        file.write(indented_xml)
        file.flush
      end

      file.write("</#{@root_element_name}>\n")
    end
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
