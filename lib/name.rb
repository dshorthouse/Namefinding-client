class Name
  attr_reader :verbatim, :scientific, :start_pos, :end_pos, :score
  
  def initialize(verbatim_name, options={})
    @verbatim = verbatim_name
    if options[:start_position]
        @start_pos = options[:start_position]
        @end_pos = @start_pos + @verbatim.length
    end
    @score = options[:score] if options[:score]
    @scientific = options[:scientific_name] if options[:scientific_name]
  end
  
  # Use this in specs
  def eql?(other_name)
    other_name.is_a?(Name) &&
    other_name.verbatim.eql?(verbatim) &&
    other_name.scientific.eql?(scientific) &&
    other_name.start_pos.eql?(start_pos) && 
    other_name.end_pos.eql?(end_pos) && 
    other_name.score.eql?(score)
  end
end
