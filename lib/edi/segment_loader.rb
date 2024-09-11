require 'json'
require_relative 'segment'

module EDI
  class SegmentLoader
    def self.load_segments_from_json(file_path)
      segments = {}
      json_data = JSON.parse(File.read(file_path))

      json_data.each do |segment_id, segment_def|
        segment_name = segment_def['name']
        elements = segment_def['elements'].map do |_, element|
          name = element['name'].to_sym
          requirement = element['requirement'] == "Mandatory" ? :mandatory : :optional
          internal_mapping = element['internal_mapping']
          # Pass keyword arguments when creating Element instances
          Element.new(name: name, requirement: requirement, internal_mapping: internal_mapping)
        end

        # Pass the `elements` array as a keyword argument
        segments[segment_id] = Segment.new(name: segment_name, elements: elements)
      end

      segments
    end
  end
end
