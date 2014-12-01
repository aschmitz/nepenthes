require 'net/https'
require 'openssl'

module Net
  class HTTP
    def set_context=(value)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context &&= OpenSSL::SSL::SSLContext.new(value)
    end
  end
end

class CipherWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :lomem_slow
  def perform(id, host, port)
    ssl_data = "Accepted Ciphers - anything below 128 Bits is BAD"
    protocol_versions = [:SSLv23, :TLSv1, :TLSv1_1, :TLSv1_2] # Set all protocol versions
    protocol_versions.each do |version|
      cipher_set = OpenSSL::SSL::SSLContext.new(version).ciphers # Get available ciphers
      cipher_data += "\n============================================\n"
      cipher_data += version.to_s
      cipher_data += "\n============================================\n"
      cipher_set.each do |cipher_name, ignore_me_cipher_version, bits, ignore_me_algorithm_bits|
        request = Net::HTTP.new(host, port)
        request.use_ssl = true
        request.set_context = version
        request.ciphers = cipher_name
        request.verify_mode = OpenSSL::SSL::VERIFY_NONE
        begin
        response = request.get("/")
        ssl_data += "[+] Accepted\t #{bits} bits\t#{cipher_name}\n" # Only return accepted ciphers
        rescue
        OpenSSL::SSL::SSLError
        rescue
        end
      end
    end
  Sidekiq::Client.enqueue(SslResults, id, cipher_data)
  end
end
