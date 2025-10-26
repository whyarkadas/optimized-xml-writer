# Memory-Efficient Ruby Hash to XML Converter

A production-ready, memory-efficient solution for converting large Ruby hash arrays to valid XML files. Designed to handle datasets of any size without loading all data into memory.

## 📁 Project Structure

```
memory-opt/
├── README.md              # This file - project documentation
├── BENCHMARK_RESULTS.md   # Detailed performance benchmarks
├── STREAMING_VS_BULK.md   # Streaming vs Bulk comparison
├── ARCHITECTURE.md        # Code organization and design
├── Gemfile               # Ruby dependencies
├── lib/                  # Core library code
│   ├── writers/          # XML writer implementations
│   │   ├── memory_efficient_xml_writer.rb  # Main streaming writer
│   │   ├── bulk_xml_writer.rb             # Bulk writer (for comparison)
│   │   └── batch_xml_writer.rb            # Batch writer with GC
│   ├── utilities/        # Helper utilities
│   │   ├── practical_xml_converter.rb     # Format converters (Yajl)
│   │   └── xml_validator.rb               # XML validation
│   ├── benchmarks/       # Performance testing
│   │   ├── xml_writer_benchmark.rb        # XML writer comparison
│   │   ├── json_xml_benchmark.rb          # JSON→XML with Yajl
│   │   └── memory_usage_demo.rb           # Memory demo
│   └── xml_writers.rb    # Loader for all classes
├── examples/             # Example scripts and demos
│   ├── practical_example.rb      # Real-world examples (JSONL)
│   └── benchmark.rb              # Performance testing
├── data/                 # Sample data files
│   └── sample_data.jsonl
└── output/               # Generated XML files (gitignored)
    └── .gitkeep
```

## 🚀 Quick Start

### Installation

```bash
# Install dependencies
bundle install
```

**Dependencies:**
- `nokogiri` - High-performance XML generation
- `yajl-ruby` - Ultra-fast streaming JSON parser (for JSON conversion)

### Basic Usage

```ruby
require_relative 'lib/writers/memory_efficient_xml_writer'

# Your data
data = [
  { id: 1, name: "John", email: "john@example.com" },
  { id: 2, name: "Jane", email: "jane@example.com" }
]

# Convert to XML
writer = MemoryEfficientXMLWriter.new('output/users.xml', 'users')
writer.write_complete_xml(data, 'user')
```

### Try the Examples

```bash
# Run examples
cd examples
ruby practical_example.rb

# Run performance benchmarks
ruby benchmark.rb
```

## ✨ Key Features

### Memory Efficiency
- **Streaming Processing**: Writes XML incrementally without loading entire dataset into memory
- **Constant Memory Usage**: Uses ~30-50MB regardless of dataset size
- **Garbage Collection**: Automatic memory management for very large datasets
- **Automatic Flushing**: Periodic disk flushing for optimal performance

### XML Generation
- **Valid XML Output**: Always produces well-formed XML with proper headers
- **Automatic Escaping**: Handles special XML characters (`, <, >, &, etc.)
- **Element Name Sanitization**: Converts invalid characters to valid XML element names
- **Nested Structures**: Supports complex nested hashes and arrays
- **Custom Elements**: Configurable root and item element names

### Flexible Input
- Ruby arrays of hashes
- Enumerators (most memory-efficient)
- JSONL (JSON Lines) files with Yajl streaming parser
- High-performance JSON processing (100K+ records/second)
- Any iterable data source

## 📖 Documentation

### Library Organization

The library is organized into logical subfolders for better code organization:

**`lib/writers/`** - Core XML writer implementations (all use Nokogiri)
- `memory_efficient_xml_writer.rb` - Main streaming writer (⭐ **recommended**)
- `bulk_xml_writer.rb` - Traditional approach (for comparison)
- `batch_xml_writer.rb` - Batch processing with GC

**`lib/utilities/`** - Helper utilities
- `practical_xml_converter.rb` - Convert JSONL, arrays to XML (uses Yajl)
- `xml_validator.rb` - Validate XML files

**`lib/benchmarks/`** - Performance testing
- `json_xml_benchmark.rb` - JSON→XML conversion benchmark (Yajl)
- `xml_writer_benchmark.rb` - XML writer comparison benchmark
- `memory_usage_demo.rb` - Memory efficiency demonstrations

**Loading Options:**

```ruby
# Option 1: Load specific classes (recommended)
require_relative 'lib/writers/memory_efficient_xml_writer'
require_relative 'lib/utilities/practical_xml_converter'

# Option 2: Load everything at once
require_relative 'lib/xml_writers'
# Now all classes are available
```

### Core Classes

#### `MemoryEfficientXMLWriter`

The main class for streaming XML generation. Recommended for most use cases.

**Location:** `lib/writers/memory_efficient_xml_writer.rb`

**Methods:**

- `initialize(file_path, root_element_name = 'data')` - Create writer instance
- `start_document` - Initialize XML file with headers
- `write_hash(hash, element_name = 'item')` - Write single hash as XML element
- `write_hash_array(array, element_name = 'item')` - Write array of hashes
- `finish_document` - Close XML properly
- `write_complete_xml(data, element_name = 'item')` - Complete workflow in one call
- `write_xml { |writer| ... }` - Block-based API for automatic resource management

**Example:**

```ruby
require_relative 'lib/writers/memory_efficient_xml_writer'

writer = MemoryEfficientXMLWriter.new('output/data.xml', 'records')
writer.start_document

# Process large dataset iteratively
large_dataset.each do |record|
  writer.write_hash(record, 'record')
end

writer.finish_document
```

### Utility Classes

The project includes several utility classes to make common tasks easier:

#### `PracticalXMLConverter`

Helper class for converting different data formats to XML using high-performance Yajl JSON parser.

**Location:** `lib/utilities/practical_xml_converter.rb`

**Methods:**
- `jsonl_to_xml(jsonl_file, xml_file)` - Convert JSONL files to XML using Yajl streaming parser
- `array_to_xml_chunked(array, xml_file, chunk_size)` - Process large arrays in chunks

**Performance:**
- Uses Yajl for ultra-fast JSON parsing (100K+ records/second)
- Streaming parser = minimal memory overhead
- Perfect for huge JSON files (500K+ records)

**Example:**
```ruby
require_relative 'lib/utilities/practical_xml_converter'

# Convert huge JSONL file with streaming parser
PracticalXMLConverter.jsonl_to_xml('data.jsonl', 'output/data.xml')
```

#### `XMLValidator`

Validate generated XML files.

**Location:** `lib/utilities/xml_validator.rb`

**Methods:**
- `validate_xml_file(xml_file)` - Validates XML structure (uses Nokogiri if available, falls back to basic validation)

**Example:**
```ruby
require_relative 'lib/utilities/xml_validator'

XMLValidator.validate_xml_file('output/data.xml')
```

#### `XMLWriterBenchmark`

Performance benchmarking for comparing different writer approaches.

**Location:** `lib/benchmarks/xml_writer_benchmark.rb`

**Example:**
```ruby
require_relative 'lib/benchmarks/xml_writer_benchmark'

benchmark = XMLWriterBenchmark.new
benchmark.run_all_benchmarks
```

#### `MemoryUsageDemo`

Demonstrates memory efficiency with large-scale datasets.

**Location:** `lib/benchmarks/memory_usage_demo.rb`

**Example:**
```ruby
require_relative 'lib/benchmarks/memory_usage_demo'

demo = MemoryUsageDemo.new
demo.demonstrate_memory_efficiency
```

### Usage Patterns

#### Pattern 1: Complete Array Conversion

Good for small to medium datasets that fit in memory.

```ruby
data = load_my_data_array
writer = MemoryEfficientXMLWriter.new('output/data.xml', 'records')
writer.write_complete_xml(data, 'record')
```

#### Pattern 2: Processing Files

Convert JSONL files to XML.

```ruby
require 'json'

writer = MemoryEfficientXMLWriter.new('output/from_jsonl.xml', 'records')
writer.start_document

File.foreach('data.jsonl') do |line|
  record = JSON.parse(line.strip)
  writer.write_hash(record, 'record')
end

writer.finish_document
```

#### Pattern 3: Using Enumerators

Create on-demand data generation without storing in memory.

```ruby
data_enumerator = Enumerator.new do |yielder|
  # Generate or fetch data one at a time
  loop do
    record = fetch_next_record_from_source
    break unless record
    yielder << record
  end
end

writer = MemoryEfficientXMLWriter.new('output/data.xml')
writer.write_complete_xml(data_enumerator, 'record')
```

## 📊 Performance Characteristics

### Memory Usage

| Dataset Size | Traditional Approach | This Solution | Memory Savings |
|-------------|---------------------|---------------|----------------|
| 1,000 records | ~2 MB | ~0.25 MB | **88%** |
| 10,000 records | ~20 MB | ~0.13 MB | **99%** |
| 100,000 records | ~200 MB | ~0.33 MB | **99.8%** |
| 500,000 records | ~2-4 GB (or OOM) | ~1.5 MB | **>99.9%** |
| 1,000,000 records | OutOfMemory | ~25 MB | **Impossible → Possible** |

### Processing Speed

- **Streaming Writer**: 11,000-13,000 records/second (consistent across all dataset sizes)
- **Scalability**: Linear - processing time scales linearly with dataset size
- **Performance**: No degradation even with 500,000+ records

### Real Benchmark Results

**Test with 500,000 records:**
```
Streaming Writer Test
   Time: 39 seconds
   Memory - Start: 25.17 MB
   Memory - Peak: 25.17 MB
   Memory - End: 23.72 MB
   Memory - Delta: -1.45 MB (decreased!)
   Output file size: 570.2 MB
   Processing speed: 12,828 records/sec
   Memory efficiency: 570:1 ratio
```

**Extreme Scale Test (100,000 complex nested records):**
```
Records processed:    100,000
Processing time:      10.94 seconds
Output file size:     191.87 MB
Memory increase:      0.25 MB
Memory efficiency:    767.5:1 ratio

💡 Generated 192MB of XML using only 0.25MB of memory!
```

📈 **See [BENCHMARK_RESULTS.md](BENCHMARK_RESULTS.md) for detailed performance analysis**  
🆚 **See [STREAMING_VS_BULK.md](STREAMING_VS_BULK.md) for Streaming vs Bulk comparison**

## 🛠️ Advanced Usage

### Complex Nested Structures

The writers automatically handle nested hashes and arrays:

```ruby
complex_data = {
  customer_id: "CUST_001",
  personal_info: {
    name: "John Doe",
    address: {
      street: "123 Main St",
      city: "Anytown"
    }
  },
  orders: [
    { id: 1, amount: 99.99 },
    { id: 2, amount: 149.50 }
  ]
}

writer = MemoryEfficientXMLWriter.new('output/complex.xml')
writer.write_complete_xml([complex_data], 'customer')
```

**Output:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<data>
  <customer>
    <customer_id>CUST_001</customer_id>
    <personal_info>
      <name>John Doe</name>
      <address>
        <street>123 Main St</street>
        <city>Anytown</city>
      </address>
    </personal_info>
    <orders>
      <id>1</id>
      <amount>99.99</amount>
    </orders>
    <orders>
      <id>2</id>
      <amount>149.50</amount>
    </orders>
  </customer>
</data>
```

### Custom Element Names

```ruby
writer = MemoryEfficientXMLWriter.new('output/catalog.xml', 'product_catalog')
writer.start_document

products.each do |product|
  writer.write_hash(product, 'product')
end

writer.finish_document
```

### Block-based API

```ruby
MemoryEfficientXMLWriter.new('output/data.xml', 'records').write_xml do |writer|
  process_data_source.each do |record|
    writer.write_hash(record, 'record')
  end
end
# File automatically closed when block exits
```

## 🏗️ Project Organization

### Why Subfolders?

The library uses a well-organized folder structure to:
- ✅ **Easy Navigation** - Find classes instantly by category
- ✅ **Clear Purpose** - Each folder has a specific responsibility
- ✅ **Scalability** - Easy to add new classes without clutter
- ✅ **Professional** - Follows Ruby gem best practices

### Adding New Classes

**Add a new writer:**
```ruby
# Create: lib/writers/my_custom_writer.rb
class MyCustomWriter < MemoryEfficientXMLWriter
  # Your implementation
end

# Update: lib/xml_writers.rb
require_relative 'writers/my_custom_writer'
```

**Add a new utility:**
```ruby
# Create: lib/utilities/my_helper.rb
class MyHelper
  # Your implementation
end

# Update: lib/xml_writers.rb
require_relative 'utilities/my_helper'
```

## 🔧 Development

### Running Tests

```bash
# Run all examples
cd examples
ruby practical_example.rb

# Run benchmarks
ruby benchmark.rb
```

### Adding Custom Functionality

The library is designed to be extended. You can create custom writers:

```ruby
class MyCustomXMLWriter < MemoryEfficientXMLWriter
  def write_with_metadata(hash, metadata)
    # Add custom logic
    start_document
    write_hash({ metadata: metadata }, 'meta')
    write_hash(hash, 'data')
    finish_document
  end
end
```

## ⚠️ Important Notes

### Thread Safety

The writers are **not thread-safe**. Use separate instances for concurrent processing or implement synchronization.

### Memory Tips

1. **Use Enumerators**: Always prefer enumerators over loading entire datasets into arrays
2. **File Streaming**: Process large input files line-by-line, don't load into memory
3. **Periodic Flushing**: The writer automatically flushes periodically to free memory

### Best Practices

```ruby
# ❌ Don't do this (loads everything into memory)
all_records = generate_all_data  # Loads millions of records
writer.write_complete_xml(all_records)

# ✅ Do this (streams data)
writer.start_document
enumerator.each do |record|
  writer.write_hash(record, 'record')
end
writer.finish_document
```

## 📝 Requirements

- **Ruby**: 2.7.0 or higher
- **Dependencies**: `nokogiri` gem (required for XML generation)
- **Installation**: `gem install nokogiri` or use `bundle install`

## 📚 Additional Resources

### Documentation Files

- **`README.md`** - This file - complete project documentation
- **`ARCHITECTURE.md`** - Detailed architecture and design decisions
- **`BENCHMARK_RESULTS.md`** - Comprehensive performance benchmarks
- **`STREAMING_VS_BULK.md`** - Comparison between approaches
- **`FOLDER_STRUCTURE_SUMMARY.md`** - Folder organization guide

### Example Files

- **`examples/practical_example.rb`** - Real-world conversions with Yajl (creates 100K JSON records)
- **`examples/benchmark.rb`** - Comprehensive performance testing
  - JSON→XML conversion benchmarks with Yajl (10K-500K records)
  - XML writer comparisons (streaming vs bulk)
  - Memory efficiency demonstrations

### Sample Data

- **`data/sample_data.jsonl`** - Generated JSONL file (100K records with nested structures)

## 🎓 Learning Path

1. **Start**: Read this README
2. **Try**: Run `examples/practical_example.rb` for real-world scenarios (100K JSON records)
3. **Optimize**: Use `examples/benchmark.rb` to test performance
   - JSON→XML conversion with Yajl (demonstrates 100K+ records/sec parsing)
   - Streaming vs bulk XML writer comparison
   - Memory efficiency demonstrations
4. **Understand**: Read `ARCHITECTURE.md` for design details
5. **Integrate**: Apply to your own project

## 🌟 Quick Reference

### Most Common Use Case

```ruby
# Load the main writer
require_relative 'lib/writers/memory_efficient_xml_writer'

# Create writer
writer = MemoryEfficientXMLWriter.new('output.xml', 'root')

# Write data
writer.start_writing
data.each { |item| writer.write_hash(item, 'item') }
writer.finish_writing
```

### File Conversions

```ruby
# Load converter
require_relative 'lib/utilities/practical_xml_converter'

# Convert files
PracticalXMLConverter.jsonl_to_xml('input.jsonl', 'output.xml')
```

### Performance Testing

```ruby
# Load benchmark
require_relative 'lib/benchmarks/xml_writer_benchmark'

# Run tests
benchmark = XMLWriterBenchmark.new
benchmark.run_all_benchmarks
```

---

### Built with ❤️ for handling massive datasets efficiently

