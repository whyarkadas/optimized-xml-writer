#!/usr/bin/env ruby

# Traditional bulk writer - loads everything into memory before writing
# This is ONLY for benchmark comparison purposes
# DO NOT use this for production - use MemoryEfficientXMLWriter instead!
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
    # Write everything at once at the end
    File.open(@file_path, 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write("\n<#{@root_element_name}>\n")

      @records.each do |record|
        xml_string = hash_to_xml_string(record[:hash], record[:element_name], 1)
        file.write(xml_string)
      end

      file.write("</#{@root_element_name}>\n")
    end

    @records.clear
  end

  private

  def hash_to_xml_string(hash, element_name, indent_level = 0)
    indent = '  ' * indent_level
    lines = ["#{indent}<#{element_name}>"]

    hash.each do |key, value|
      case value
      when Hash
        lines << hash_to_xml_string(value, escape_xml_name(key.to_s), indent_level + 1)
      when Array
        value.each do |item|
          if item.is_a?(Hash)
            lines << hash_to_xml_string(item, escape_xml_name(key.to_s), indent_level + 1)
          else
            lines << "#{indent}  <#{escape_xml_name(key.to_s)}>#{escape_xml_content(item.to_s)}</#{escape_xml_name(key.to_s)}>"
          end
        end
      else
        lines << "#{indent}  <#{escape_xml_name(key.to_s)}>#{escape_xml_content(value.to_s)}</#{escape_xml_name(key.to_s)}>"
      end
    end

    lines << "#{indent}</#{element_name}>"
    lines.join("\n") + "\n"
  end

  def escape_xml_name(name)
    name.gsub(/[^a-zA-Z0-9_-]/, '_').gsub(/^[^a-zA-Z_]/, '_')
  end

  def escape_xml_content(content)
    content.gsub('&', '&amp;')
           .gsub('<', '&lt;')
           .gsub('>', '&gt;')
           .gsub('"', '&quot;')
           .gsub("'", '&apos;')
  end
end
