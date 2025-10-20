#!/usr/bin/env ruby

require_relative '../lib/writers/memory_efficient_xml_writer'
require 'time'

# Ensure we're in the project root directory
Dir.chdir(File.expand_path('..', __dir__))

# Quick Usage Guide for Memory-Efficient XML Writer
# This demonstrates the most common scenarios you'll encounter

# ==============================================================================
# SCENARIO 1: You have a Ruby array of hashes and want to convert to XML
# ==============================================================================

puts "Scenario 1: Converting array of hashes to XML"
puts "-" * 50

# Your data (could come from database, API, CSV, etc.)
user_data = [
  { id: 1, name: "Alice", email: "alice@example.com", active: true },
  { id: 2, name: "Bob", email: "bob@example.com", active: false },
  { id: 3, name: "Charlie", email: "charlie@example.com", active: true }
]

# Convert to XML - Memory efficient way
writer = MemoryEfficientXMLWriter.new('output/users.xml', 'users')
writer.start_writing
user_data.each { |user| writer.write_hash(user, 'user') }
writer.finish_writing

puts "✓ Created output/users.xml from array of #{user_data.length} hashes"

# ==============================================================================
# SCENARIO 2: Processing large dataset from database (ActiveRecord example)
# ==============================================================================

puts "\nScenario 2: Processing large dataset (simulated database)"
puts "-" * 50

# Simulate database cursor or batch processing
def simulate_database_batches(&block)
  # This simulates ActiveRecord's find_in_batches or similar
  total_records = 10_000
  batch_size = 1_000

  (0...total_records).step(batch_size) do |offset|
    batch = []
    batch_size.times do |i|
      record_id = offset + i + 1
      break if record_id > total_records

      batch << {
        id: record_id,
        name: "User #{record_id}",
        email: "user#{record_id}@example.com",
        created_at: Time.now.iso8601,
        metadata: {
          score: rand(100),
          active: [true, false].sample
        }
      }
    end

    yield batch unless batch.empty?
  end
end

# Memory-efficient processing
writer = MemoryEfficientXMLWriter.new('output/large_users.xml', 'users')
writer.start_writing

total_processed = 0
simulate_database_batches do |batch|
  batch.each do |user_hash|
    writer.write_hash(user_hash, 'user')
    total_processed += 1
  end
  puts "Processed #{total_processed} records..." if total_processed % 2000 == 0
end

writer.finish_writing
puts "✓ Created output/large_users.xml with #{total_processed} records"

# ==============================================================================
# SCENARIO 3: Processing data with complex nested structures
# ==============================================================================

puts "\nScenario 3: Complex nested data structures"
puts "-" * 50

complex_data = [
  {
    customer_id: "CUST_001",
    personal_info: {
      name: "John Doe",
      email: "john@example.com",
      address: {
        street: "123 Main St",
        city: "Anytown",
        country: "USA"
      }
    },
    orders: [
      {
        order_id: "ORD_001",
        date: "2023-01-15",
        items: [
          { name: "Product A", price: 29.99, quantity: 2 },
          { name: "Product B", price: 49.99, quantity: 1 }
        ],
        total: 109.97
      },
      {
        order_id: "ORD_002",
        date: "2023-02-20",
        items: [
          { name: "Product C", price: 19.99, quantity: 3 }
        ],
        total: 59.97
      }
    ],
    settings: {
      newsletter: true,
      notifications: {
        email: true,
        sms: false,
        push: true
      }
    }
  }
]

writer = MemoryEfficientXMLWriter.new('output/complex_data.xml', 'customers')
writer.start_writing
complex_data.each { |customer| writer.write_hash(customer, 'customer') }
writer.finish_writing

puts "✓ Created output/complex_data.xml with nested structures"

# ==============================================================================
# SCENARIO 4: Processing huge datasets (50K+ records)
# ==============================================================================

puts "\nScenario 4: Processing huge datasets efficiently"
puts "-" * 50

# Streaming writer handles huge datasets with constant memory
writer = MemoryEfficientXMLWriter.new('output/huge_dataset.xml', 'records')
writer.start_writing

# Simulate processing 50,000 records
(1..50_000).each do |i|
  record = {
    id: i,
    timestamp: Time.now.iso8601,
    data: "Record #{i}",
    random_value: rand(1000)
  }

  writer.write_hash(record, 'record')

  # Optional: Force GC periodically for very large datasets
  GC.start if i % 5000 == 0

  puts "Processed #{i} records..." if i % 10_000 == 0
end

writer.finish_writing
puts "✓ Created output/huge_dataset.xml with 50,000 records using streaming"

# ==============================================================================
# SCENARIO 5: Custom element names and root elements
# ==============================================================================

puts "\nScenario 5: Custom XML structure"
puts "-" * 50

products = [
  { sku: "PROD001", name: "Widget A", price: 29.99 },
  { sku: "PROD002", name: "Widget B", price: 39.99 }
]

# Custom root element name and item element names
writer = MemoryEfficientXMLWriter.new('output/catalog.xml', 'product_catalog')
writer.start_writing

products.each do |product|
  writer.write_hash(product, 'product')
end

writer.finish_writing
puts "✓ Created output/catalog.xml with custom element names"

# ==============================================================================
# CLEAN UP AND SUMMARY
# ==============================================================================

puts "\n" + "=" * 70
puts "SUMMARY - Generated Files:"
puts "=" * 70

files = Dir.glob('output/*.xml').sort
files.each do |file|
  size = File.size(file)
  size_mb = (size / 1024.0 / 1024.0).round(3)
  filename = File.basename(file)
  puts "  #{filename.ljust(25)} - #{size_mb.to_s.rjust(8)} MB"
end

puts "\nAll XML files are valid and generated with minimal memory usage!"
puts "You can now integrate this approach into your own applications."

# Optionally clean up demo files
puts "\nClean up demo files? (y/n)"
response = gets.chomp.downcase
if response == 'y' || response == 'yes'
  files.each { |file| File.delete(file) }
  puts "Demo files cleaned up!"
end
