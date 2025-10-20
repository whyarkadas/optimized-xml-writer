#!/usr/bin/env ruby

# Simple example of using the memory-efficient XML writer
require_relative 'memory_efficient_xml_writer'

# Example of processing a huge dataset with minimal memory usage
def process_huge_dataset
  # Simulate a huge dataset source (could be database, API, large file, etc.)
  huge_dataset = (1..10000).lazy.map do |i|
    {
      id: i,
      name: "User #{i}",
      email: "user#{i}@example.com",
      created_at: Time.now - rand(365 * 24 * 3600),
      preferences: {
        theme: ["dark", "light", "auto"].sample,
        notifications: rand(2) == 1,
        language: ["en", "es", "fr", "de"].sample
      },
      stats: {
        login_count: rand(1..1000),
        last_active: Time.now - rand(30 * 24 * 3600),
        premium: rand(10) == 1 # 10% premium users
      }
    }
  end

  puts "Processing huge dataset (10,000 records) with minimal memory usage..."

  # Process in chunks to minimize memory usage
  writer = MemoryEfficientXMLWriter.new('./huge_dataset.xml', 'users')
  writer.start_writing

  # Process records one by one with periodic progress updates
  huge_dataset.each_with_index do |record, index|
    if (index + 1) % 500 == 0
      puts "  Processed #{index + 1} records..."
    end

    writer.write_hash(record, 'user')

    # Force garbage collection periodically to keep memory usage low
    GC.start if (index + 1) % 2000 == 0
  end

  writer.finish_writing
  puts "✓ Successfully created huge_dataset.xml"

  # Show file size
  file_size = File.size('./huge_dataset.xml')
  puts "File size: #{file_size} bytes (#{(file_size / 1024.0 / 1024.0).round(2)} MB)"
end

# Example with custom data structure
def process_custom_data
  puts "\nProcessing custom business data..."

  # Sample business data
  business_records = [
    {
      company_id: 1,
      name: "Acme Corp",
      address: {
        street: "123 Main St",
        city: "Anytown",
        state: "CA",
        zip: "90210",
        country: "USA"
      },
      employees: [
        { name: "John Doe", position: "CEO", salary: 200000 },
        { name: "Jane Smith", position: "CTO", salary: 180000 }
      ],
      financials: {
        revenue: 5000000,
        expenses: 3500000,
        profit: 1500000,
        year: 2023
      }
    },
    {
      company_id: 2,
      name: "Tech Solutions Inc",
      address: {
        street: "456 Innovation Dr",
        city: "Silicon Valley",
        state: "CA",
        zip: "94000",
        country: "USA"
      },
      employees: [
        { name: "Bob Johnson", position: "Founder", salary: 250000 },
        { name: "Alice Brown", position: "Lead Developer", salary: 150000 },
        { name: "Charlie Wilson", position: "Designer", salary: 120000 }
      ],
      financials: {
        revenue: 2000000,
        expenses: 1200000,
        profit: 800000,
        year: 2023
      }
    }
  ]

  # Write using block syntax for automatic resource management
  MemoryEfficientXMLWriter.new('./business_data.xml', 'companies').write_xml do |writer|
    business_records.each do |record|
      writer.write_hash(record, 'company')
    end
  end

  puts "✓ Successfully created business_data.xml"
end

# Run examples
if __FILE__ == $0
  puts "Memory-Efficient XML Writer Examples"
  puts "=" * 40

  # Example 1: Huge dataset with minimal memory
  process_huge_dataset

  # Example 2: Custom business data
  process_custom_data

  puts "\nAll examples completed successfully!"
  puts "Check the generated XML files to see the results."
end
