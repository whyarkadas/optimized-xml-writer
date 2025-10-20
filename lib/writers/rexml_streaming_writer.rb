#!/usr/bin/env ruby

require 'rexml/document'
require 'rexml/formatters/pretty'

# Alternative streaming approach using REXML library
# Produces slightly cleaner XML output but uses more memory than MemoryEfficientXMLWriter
# Good for smaller datasets where XML formatting is important
class REXMLStreamingWriter
  def initialize(file_path, root_element_name = 'data')
    @file_path = file_path
    @root_element_name = root_element_name
  end

  def write_hashes(hash_array, element_name = 'item')
    File.open(@file_path, 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write("\n<#{@root_element_name}>\n")

      hash_array.each do |hash|
        element = hash_to_xml_element(hash, element_name)
        formatter = REXML::Formatters::Pretty.new(2)
        output = ""
        formatter.write(element, output)
        file.write("  #{output.strip}\n")
        file.flush
      end

      file.write("</#{@root_element_name}>\n")
    end
  end

  private

  def hash_to_xml_element(hash, element_name)
    element = REXML::Element.new(element_name)
    add_hash_to_element(element, hash)
    element
  end

  def add_hash_to_element(parent, hash)
    hash.each do |key, value|
      case value
      when Hash
        child = parent.add_element(key.to_s)
        add_hash_to_element(child, value)
      when Array
        value.each do |item|
          if item.is_a?(Hash)
            child = parent.add_element(key.to_s)
            add_hash_to_element(child, item)
          else
            child = parent.add_element(key.to_s)
            child.text = item.to_s
          end
        end
      else
        child = parent.add_element(key.to_s)
        child.text = value.to_s
      end
    end
  end
end
