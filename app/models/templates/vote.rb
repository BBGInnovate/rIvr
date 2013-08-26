require 'dropbox'
require 'open-uri'
require 'builder'

class Vote < Template
  HUMANIZED_COLUMNS = {:identifier=>"Name"}
    
      def self.human_attribute_name(attribute, options = {})
        HUMANIZED_COLUMNS[attribute.to_sym] ||
        attribute.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
      end
      
    validates :identifier, :presence => true, :length => {:minimum=>6, :maximum => 40 }
end