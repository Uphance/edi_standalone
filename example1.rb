require_relative 'lib/edi/segment_loader'
require_relative 'lib/edi/parser'


una_segment = {
  'segment' => "'",
  'element' => '+',
  'component' => ':',
  'repetition' => '*',
  'decimal' => '.',
  'release' => '?'
}


segment_definitions = EDI::SegmentLoader.load_segments_from_json('config/segments.json')
parser = EDIParser.new(segment_definitions)
puts JSON.pretty_generate(parser.parse('edi_file.txt'))
