require 'ostruct'
class Option < ActiveRecord::Base
  belongs_to :branch
  def to_label
    "Option"
  end
  def branch_name
    if branch
      branch.name
    else
      'Global Option'
    end
  end
  def public_url
    if self.name == 'recording_url'
      self.value
    else
      nil
    end
  end

end
