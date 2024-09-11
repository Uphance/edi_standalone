# lib/edi/segment.rb
  class Element
    attr_accessor :name, :requirement, :internal_mapping

    def initialize(name:, requirement:, internal_mapping: nil)
      @name = name
      @requirement = requirement
      @internal_mapping = internal_mapping
    end
  end

  
  # Segment class in segment.rb
  class Segment
    attr_accessor :name, :elements

    def initialize(name:, elements:)
      @name = name
      @elements = elements
    end
  end

  