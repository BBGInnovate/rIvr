#module Kaltura
#  class MediaEntry < DelegateClass(Hashie::Mash)
#    def self.upload(id,version=nil)
#      fetch('media', 'post', {:entryId => id, :version => version})
#    end
#  end
#end
#
#Kaltura.configure do |config|
#  config.partner_id = 1175831
#  config.administrator_secret = '15adcfc9bdc5962caf963d1338b0f738'
#  config.service_url = 'http://www.kaltura.com'
#end
#Kaltura::MediaEntry.list
#Kaltura::MediaEntry.get '1_zskvknls'


#require 'kaltura'
#vi /Users/lliu/Downloads/BBG/kaltura-ruby/lib/kaltura/kaltura_client_base.rb
#add rescue
#begin
#  instance.send(self.underscore(element.name) + "=", value);
#rescue
#  puts "AAA #{$!.message}"
#end
                                                       
# These values may be retrieved from your KMC account
#login_email = 'lliu@metrostarsystems.com'
#login_password = 'Changsha6!'
#partner_id = 1175831
#subpartner_id = 117583100
#admin_secret = '15adcfc9bdc5962caf963d1338b0f738'
#user_secret = 'a638b2f8fe746852de31344252a31a7e'
#config = Kaltura::Configuration.new( partner_id )
#client = Kaltura::Client.new( config )
#session = client.session_service.start( admin_secret, '', Kaltura::Constants::SessionType::ADMIN )
#client.ks = session
#filter = Kaltura::Filter::BaseFilter.new
#pager = Kaltura::FilterPager.new
#media = client.media_service.list(filter, pager)
#a=media.objects.last
#a.data_url
#video = File.open("/Users/lliu/vidcon/public/samples/bonjour.mp4")
#client.media_service.upload(video)


