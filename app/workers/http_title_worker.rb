require 'nokogiri'
require 'net/http'

class HttpTitleWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_fast
  
  def perform(id, ip, port)
    title = ""
    protocol = "http://"
    if port == 443
      protocol = "https://"
    end
    
    html_doc = Nokogiri::HTML(open("#{protocol}#{ip}:#{port}"))
    title = html_doc.title
    Sidekiq::Client.enqueue(HttpTitleResults, id, title)
  end
end
