require 'openssl'
require 'date'

CERT_REGEX = /-----BEGIN CERTIFICATE-----[^-]*-----END CERTIFICATE-----/

class SslResults
  include Sidekiq::Worker
  sidekiq_options :queue => :results
  
  def perform(id, ssl_data)
    port = Port.find_by_id(id)
    return unless port
    port.settings['ssl_details'] = ssl_data
    port.ssl = ssl_data.include?('SSL-Session')
    
    if cert_match = ssl_data.match(CERT_REGEX)
      cert = OpenSSL::X509::Certificate.new(cert_match[0])
      expiry_date = cert.not_after.to_s
      port.notes ||= ''
      # We add a space after slashes to wrap long lines.
      if Date.parse(expiry_date) > Date.today
        port.notes += "Certificate is valid\n"
      else
        port.notes += "Certificate is out of date\n"
      end
      port.notes += "SSL For: #{cert.subject.to_s.gsub('/', '/ ')}\n"
      cert.extensions.each do |extension|
        if extension.oid == 'subjectAltName'
          port.notes += "#{extension.value.gsub(', ', "\n")}\n"
        end
      end
    end
    port.save!
  end
end
