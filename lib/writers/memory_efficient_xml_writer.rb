#!/usr/bin/env ruby

# Memory-efficient XML writer that streams data directly to file
# without loading entire dataset into memory
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
