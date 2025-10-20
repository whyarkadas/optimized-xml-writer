#!/usr/bin/env ruby

# Main loader file for all XML writer classes and utilities
# Require this file to get access to all implementations

# Writers - Core XML writing implementations
require_relative 'writers/memory_efficient_xml_writer'
require_relative 'writers/bulk_xml_writer'
require_relative 'writers/batch_xml_writer'
require_relative 'writers/rexml_streaming_writer'

# Utilities - Helper classes for conversion and validation
require_relative 'utilities/practical_xml_converter'
require_relative 'utilities/xml_validator'

# Benchmarks - Performance testing and demonstrations
require_relative 'benchmarks/xml_writer_benchmark'
require_relative 'benchmarks/memory_usage_demo'
