xml.instruct!
xml.names("xmlns" =>"http://globalnames.org/namefinder", "xmlns:dwc" => "http://rs.tdwg.org/dwc/terms/") do
  @names.each do |name|
    xml.name do
      xml.verbatim name.verbatim
      xml.dwc(:scientificName, name.scientific) if name.scientific
      xml.score(name.score) if name.score
      xml.offset(:start => name.start_pos, :end => name.end_pos) if name.start_pos
    end
  end    
end
