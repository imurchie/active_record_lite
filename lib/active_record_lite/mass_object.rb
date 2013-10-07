class MassObject
  def self.my_attr_accessible(*attributes)
    attributes.each do |attribute|
      attr_accessor attribute
      self.attributes << attribute.to_s
    end
  end

  def self.attributes
    @attributes ||= []
  end

  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  def initialize(params = {})
    params.each do |attribute, value|
      attribute = attribute.to_s

      if self.class.attributes.include?(attribute)
        self.send("#{attribute}=", value)
      else
        raise "[#{self.class}]: mass assignment to unregistered attribute #{attribute}"
      end
    end
  end
end
