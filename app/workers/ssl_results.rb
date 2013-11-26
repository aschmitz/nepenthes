require 'openssl'

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
      port.notes ||= ''
      # We add a space after slashes to wrap long lines.
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
