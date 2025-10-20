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
