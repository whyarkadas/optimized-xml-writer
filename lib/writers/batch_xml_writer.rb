#!/usr/bin/env ruby

require_relative 'memory_efficient_xml_writer'

# Enhanced version for very large datasets with batch processing and GC optimization
# Inherits from MemoryEfficientXMLWriter and adds automatic batch management
class BatchXMLWriter < MemoryEfficientXMLWriter
  def initialize(file_path, root_element_name = 'data', batch_size = 1000)
    super(file_path, root_element_name)
    @batch_size = batch_size
    @current_batch = []
  end

  def add_to_batch(hash, element_name = 'item')
    @current_batch << { hash: hash, element_name: element_name }

    if @current_batch.size >= @batch_size
      flush_batch
    end
  end

  def flush_batch
    return if @current_batch.empty?

    @current_batch.each do |item|
      write_hash(item[:hash], item[:element_name])
    end

    @current_batch.clear
    GC.start # Force garbage collection to free memory
  end

  def finish_writing
    flush_batch # Write any remaining items
    super
  end
end
