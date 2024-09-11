require_relative 'lib/edi/segment_loader'
require_relative 'lib/edi/parser'



segment_definitions = EDI::SegmentLoader.load_segments_from_json('config/segments.json')
parser = EDIParser.new(segment_definitions)
puts JSON.pretty_generate(parser.parse('edi_file.txt'))
