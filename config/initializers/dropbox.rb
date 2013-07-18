require 'ostruct'
def hashes2ostruct(object)
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = hashes2ostruct(value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| hashes2ostruct(i) }
  else
    object
  end
end
res = YAML.load_file("#{::Rails.root}/config/dropbox.yml")
DROPBOX = hashes2ostruct res.delete(Rails.env)
res = YAML.load_file("#{::Rails.root}/config/soundcloud.yml")
SOUNDCLOUD = hashes2ostruct res.delete(Rails.env)
res = YAML.load_file("#{::Rails.root}/config/youtube.yml")
YOUTUBE = hashes2ostruct res.delete(Rails.env)

