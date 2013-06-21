#Dropbox::API::Config.app_key='0pk3wj3qyq7be7q'
#Dropbox::API::Config.app_secret='v6ujmd2ywlcgtq7'
#Dropbox::API::Config.mode= "dropbox"
# https://github.com/kenpratt/dropbox-client-ruby
def symbolize_keys(hash)
    hash.inject({}){|res, (key, val)|
      nkey = case key
        when String
        key.to_sym
      else
        key
      end
      nval = case val
        when Hash, Array
        symbolize_keys(val)
      else
        val
      end
      res[nkey] = nval
      res
    }
end

conf = "#{::Rails.root}/config/dropbox.yml"
res = YAML.load_file(conf)
DROPBOX = symbolize_keys res.delete(Rails.env)

    
