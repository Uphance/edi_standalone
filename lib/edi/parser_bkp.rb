# lib/edi/parser.rb
require_relative 'segment_loader'

class EDIParser
  def initialize(segment_definitions)
    @segment_definitions = segment_definitions
  end

  def parse(file_path)
    file_content = File.read(file_path).strip
    
    # Check if UNA segment is present
    if file_content.start_with?("UNA")
      # Extract UNA segment for delimiters
      una_segment = file_content.slice!(0, file_content.index("'") + 1)
      extract_delimiters(una_segment)
    end

    # Split the file content into segments based on segment terminator (')
    segments = file_content.split("'")
    obj = {
      standard: 'EDIFACT',
      type: '',
      content: null
    }

    segments.each do |segment|
      next if segment.strip.empty?

      segment_id = segment[0..2]  # Segment ID is the first 3 characters
      if @segment_definitions.key?(segment_id)
        segment_def = @segment_definitions[segment_id]
        process_segment(segment_id, segment_def, segment)
      else
        puts "Unknown segment ID: #{segment_id}"
      end
    end
  end

  private

  def extract_delimiters(una_segment)
    # Remove the "UNA:" prefix and trailing single quote
    delimiters_part = una_segment
  
    # Extract each delimiter based on position
    @data_element_separator = delimiters_part[4] 
    @decimal_point = delimiters_part[5]          
    @segment_terminator = delimiters_part[-1]     
    @release_indicator = delimiters_part[6]      
    @sub_element_separator = delimiters_part[3]  
  
    puts "Extracted delimiters: Decimal point: #{@decimal_point}, Segment terminator: #{@segment_terminator}, Data element separator: #{@data_element_separator}, Release indicator: #{@release_indicator}, Sub-element separator: #{@sub_element_separator}"
    puts "~~~~~~~~~"
  end
  

  def extract_delimiters_old(una_segment)
    # Extract the delimiters part of UNA segment, which is after the "UNA:" prefix
    delimiters_part = una_segment.split('+')[1].strip
    
    # Ensure delimiters_part is at least 5 characters long to cover all delimiters
    if delimiters_part.length >= 5
      @decimal_point = delimiters_part[0]
      @data_element_separator = delimiters_part[1]
      @release_indicator = delimiters_part[2]
      @segment_terminator = delimiters_part[3]
      @sub_element_separator = delimiters_part[4]
    else
      # Handle cases where delimiters part is shorter than expected
      @decimal_point = delimiters_part[0] if delimiters_part.length > 0
      @data_element_separator = delimiters_part[1] if delimiters_part.length > 1
      @release_indicator = delimiters_part[2] if delimiters_part.length > 2
      @segment_terminator = delimiters_part[3] if delimiters_part.length > 3
      @sub_element_separator = delimiters_part[4] if delimiters_part.length > 4
    end
  
    # Ensure that segment terminator is typically set to the single quote `'`
    @segment_terminator ||= "'"
  
    # Ensure that release indicator is typically `?`
    @release_indicator ||= "?"
  
    # Ensure that sub-element separator is typically `:`
    @sub_element_separator ||= ":"
  
    puts "Extracted delimiters: Decimal point: #{@decimal_point}, Segment terminator: #{@segment_terminator}, Data element separator: #{@data_element_separator}, Release indicator: #{@release_indicator}, Sub-element separator: #{@sub_element_separator}"
  end
  
  


  def process_segment(segment_id, segment_def, line)
    puts "Processing segment: #{segment_def.name}"
  
    # Remove segment ID (first 3 characters) and any leading/trailing whitespace
    segment_content = line[4..-1].strip  # Skip segment ID and any trailing whitespace
  
    # Split the segment content into elements based on the data element separator
    # p segment_content
    # p @data_element_separator
    elements = segment_content.split(@data_element_separator)
  
    # Ensure elements match the segment definition's length
    num_elements = segment_def.elements.size
  
    # Pad with empty strings if necessary
    if num_elements > elements.size
      elements += Array.new(num_elements - elements.size, "")
    elsif num_elements < elements.size
      # Trim excess elements if there are more than expected
      elements = elements[0, num_elements]
    end
  
    obj = {
      `#{}`
    }
    # Output the elements based on the segment definition
    segment_def.elements.each_with_index do |element, index|
      value = elements[index].to_s.strip
      value = "Not provided" if value.empty?
      puts "Element: #{element.name}, Value: #{value}, Requirement: #{element.requirement}"
    end
  
    puts "-------------------------"


  end
  
  
  
  
  
end
