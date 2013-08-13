require "nokogiri"

# The POSLavu API principally operates on database results exchanged in
# XML fragments. These are encapsulated as POSLavu::result objects, which
# is really just a Hash with some additional methods.
class POSLavu::Result < Hash
  # Instantiate a result, optionally copying an existing Hash.
  def initialize(hash_to_copy = nil)
    if hash_to_copy
      hash_to_copy.each { |key,value|
        self[key.to_sym] = value.to_s
      }
    end
  end
  
  # Instantiate a result given a string containing a <tt><result/></tt> XML fragment.
  # This XML fragment must contain exactly one <tt><result></tt> element at the root.
  def self.from_xml(string)
    fragment = Nokogiri::XML.fragment(string)
    from_nokogiri(fragment)
  end
  
  # Instantiate a result from a Nokogiri::XML::Node or similar. If you're using
  # the public interface, you shouldn't ever need to call this.
  def self.from_nokogiri(xml)   # :nodoc:
    raise ArgumentError, "argument is not a Nokogiri node" unless xml.kind_of?(Nokogiri::XML::Node)

    if xml.element? && xml.name == 'result'
      xml_result = xml
    else
      results = xml.xpath('./result')
      raise ArgumentError, "argument does not directly contain a <result> element" if results.empty?
      raise ArgumentError, "argument contains more than one <result> element" if results.size > 1
      
      xml_result = results.first
    end
    
    new.tap { |result|
      xml_result.element_children.each { |element|
        result[element.name.to_sym] = element.text
      }
    }
  end
  
  # Adds this result to a Nokogiri::XML::Node. If you're using the public
  # interface, you shouldn't ever need to call this.
  def to_nokogiri(doc)  # :nodoc:
    result = doc.create_element('result'); doc.add_child(result)
    each { |key,value|
      element = doc.create_element(key.to_s)
      element.add_child(doc.create_text_node(value.to_s))
      result.add_child(element)
    }
    result
  end

  # Transform this result into a string containing a <tt><result/></tt> XML fragment
  def to_xml
    doc = Nokogiri::XML::Document.new
    element = to_nokogiri(doc)
    element.to_s
  end
end
