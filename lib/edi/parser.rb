require_relative 'segment_loader'

class EDIParser
  def initialize(segment_definitions)
    @segment_definitions = segment_definitions
    @data_element_separator = '+'
    @segment_terminator = "'"
    @sub_element_separator = ":"
    @decimal_point = "."
    @release_indicator = "?"
    @type = ''  # Initialize type
    @escape_map = {}
    @reverse_escape_map = {}
  end

  def parse(file_path)
    file_content = File.read(file_path).strip

    # Check if UNA segment is present
    if file_content.start_with?("UNA")
      una_segment = file_content.slice!(0, file_content.index("'") + 1)
      extract_delimiters(una_segment)
    end

    # Handle release indicators and escape characters
    file_content = handle_release_indicators(file_content) unless file_content.empty?
    
    # Split file content into segments
    segments = file_content.split(@segment_terminator)  # Use the segment terminator to split
    obj = {
      standard: 'EDIFACT',
      type: @type,  # Set type with value from UNH segment
      content: {}
    }

    unknown_segments = []
    segments.each do |segment|
      next if segment.strip.empty?

      segment_id = segment[0..2]  # Extract segment ID
      if @segment_definitions.key?(segment_id)
        segment_def = @segment_definitions[segment_id]
        if segment_id == 'UNH'
          # Extract the type from the UNH segment
          segment_content = process_segment(segment_id, segment_def, segment)
          @type = segment_content[segment_id]['message_type'] if segment_content[segment_id]
        else
          segment_content = process_segment(segment_id, segment_def, segment)
          # Append the processed segment content into obj[:content]
          if segment_content
            if obj[:content].key?(segment_id)
              obj[:content][segment_id] << segment_content[segment_id]
            else
              obj[:content][segment_id] = [segment_content[segment_id]]
            end
          end
        end
      else
        unknown_segments.push(segment_id)
      end
    end

    # Ensure the final type value is set in obj
    obj[:type] = @type
    
    # Replace escape characters in the final output
    # replace_escape_characters!(obj)
    
    # Print unknown segments
    unknown_segments = unknown_segments.uniq
    puts "Unknown Segments: #{unknown_segments}"

    obj  # Return the parsed object
  end

  private

  def extract_delimiters(una_segment)
    delimiters_part = una_segment[4..-2].strip  # Skip "UNA:" prefix and trailing single quote
    @data_element_separator = delimiters_part[0]
    @decimal_point = delimiters_part[1]
    @release_indicator = delimiters_part[2]
    @segment_terminator = delimiters_part[3] || "'"
    @sub_element_separator = delimiters_part[4]

    puts "Extracted delimiters: Decimal point: #{@decimal_point}, Segment terminator: #{@segment_terminator}, Data element separator: #{@data_element_separator}, Release indicator: #{@release_indicator}, Sub-element separator: #{@sub_element_separator}"
  end

  def process_segment(segment_id, segment_def, segment_line)
    # Remove segment ID and strip leading/trailing whitespace
    segment_content = segment_line[4..-1].strip
  
    # Split content into elements
    elements = segment_content.split(@data_element_separator)
  
    # Ensure the number of elements matches the segment definition
    num_elements = segment_def.elements.size
    elements = adjust_element_size(elements, num_elements)
  
    # Create a hash to store segment data
    segment_data = {}
  
    # Populate segment_data with element values
    segment_def.elements.each_with_index do |element_def, index|
      value = elements[index].to_s.strip
      value = "Not provided" if value.empty?
      value = restore_escape_characters(value)
  
      # Use the internal mapping if it's available in element_def
      internal_mapping = element_def.internal_mapping
  
      # Store element value in the segment_data hash
      segment_data[internal_mapping] = value if internal_mapping
    end
  
    { segment_id => segment_data }  # Return as a hash with segment ID as key
  end

  # Adjust elements size to match segment definition
  def adjust_element_size(elements, num_elements)
    if elements.size < num_elements
      elements += Array.new(num_elements - elements.size, "")  # Pad with empty strings
    elsif elements.size > num_elements
      elements = elements[0, num_elements]  # Trim extra elements
    end
    elements
  end

  def replace_escape_characters!(obj)
    # Traverse through the obj content and apply the reverse escape map
    obj[:content].each do |segment_id, segment_data_array|
      segment_data_array.each do |segment_data|
        segment_data.transform_values! do |value|
          if value.is_a?(String)
            value.gsub(/([A-Z])/) { |match| @reverse_escape_map[match] || match }
          else
            value
          end
        end
      end
    end
  end

  def generate_unique_placeholder
    # Define a set of special Latin characters for placeholders
    latin_chars = ['é', 'ö', 'ü', 'à', 'è', 'ç', 'ã', 'î', 'ô', 'ù']
    
    # Pick a random Latin character from the set
    latin_chars.sample
  end

  def handle_release_indicators(file_content)
    # Hard-coded escape characters to handle
    # escape_sequences = ["?'", "?+", "?\\"]
    escape_sequences = ["?'"]
  
    escape_sequences.each do |escape_seq|
      placeholder = generate_unique_placeholder
  
      # Track the escape sequences and their placeholders
      @escape_map[escape_seq] = placeholder
      @reverse_escape_map[placeholder] = escape_seq
  
      # Replace escape sequences with placeholders
      file_content.gsub!(escape_seq, placeholder)
    end
  
    file_content
  end
  
  

  def restore_escape_characters(value)
    @reverse_escape_map.each do |placeholder, escape_seq|
      value = value.gsub(placeholder, escape_seq[1])
    end
    value
  end
end
