class Soundkloud< ActiveRecord::Base
#  belongs_to :entry
  self.table_name = "soundclouds"
  validates_presence_of :title
  validates_length_of   :title, :in => 1..60, :allow_blank => false
  validates_length_of   :description, :in => 3..255, :allow_blank => true
  validates_length_of   :genre, :in => 3..40, :allow_blank => true 
end