class BatchIpWorker
  include SidekiqStatus::Worker
  sidekiq_options queue: "batch_queue"

  CONCURRENT_IPS = 5000
  IP_REGEX = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:\/\d+)?/

  def perform(action, parameters={})
    if action == "create"
      batch_create(parameters)
    elsif action == "delete"
      batch_delete(parameters)
    end
  end

  def batch_create(parameters)
    base_tags = parameters["tags"].gsub(/\s+,\s*/m, ' ').strip.split(" ")
    base_tags.push(Region.find_by_id(parameters["region_id"]).name)

    # Convert input to IPS
    parsed_ips = text_to_ips(parameters["addresses"])

    # Keep track of the total number of ips to process for client status
    process_index_count = 0
    self.total = parsed_ips.count
    self.at(process_index_count)

    # Process IP's in chunks. Chunk size is set by the CONCURRENT_IPS constant.
    parsed_ips.each_slice(CONCURRENT_IPS) do |address_and_tags_slice|

      ActiveRecord::Base.transaction do
        address_and_tags_slice.each do |address_and_tags|
          newAddress = IpAddress.find_or_create_by(address: address_and_tags[0].to_i(:ip))
          newAddress.region_id = parameters["region_id"]
          newAddress.tag_list = base_tags.concat(address_and_tags[1]).join(', ')
          newAddress.save

          # Update worker statistics
          process_index_count += 1
          self.at(process_index_count)
        end
      end
    end
  end

  def batch_delete(parameters)
    # Convert input to IPS
    parsed_ips = text_to_ips(parameters["addresses"])

    # Keep track of the total number of ips to process for client status
    process_index_count = 0
    self.total = parsed_ips.count
    self.at(process_index_count)

    parsed_ips.each_slice(CONCURRENT_IPS) do |address_and_tags_slice|

      ActiveRecord::Base.transaction do
        address_and_tags_slice.each do |address_and_tags|
          addr = IpAddress.find_by_address(address_and_tags[0].to_i(:ip))
          if addr
            addr.destroy
          end

          # Update worker statistics
          process_index_count += 1
          self.at(process_index_count)
        end
      end
    end
  end

  def text_to_ips(addresses)
    allAddresses = []
    addresses.each_line do |line|
      next if line.strip == ''

      parts = line.gsub(/\s+/m, ' ').strip.split(" ")
      address_begin = parts.shift
      unless IP_REGEX.match(address_begin)
        flash[:error] = address_begin+' is not an IP address'
      end

      addresses = address_begin.scan(IP_REGEX)
      address_begin = NetAddr::CIDR.create(addresses[0])
      if addresses.length > 1
        address_end = NetAddr::CIDR.create(addresses[1])
      else
        address_end = address_begin
      end

      parts.shift if parts[0] == '-'

      if IP_REGEX.match(parts[0])
        address_end = NetAddr::CIDR.create(parts.shift.scan(IP_REGEX)[0])
      end

      (address_begin..address_end).each do |address|
        allAddresses << [address, parts]
      end
    end

    allAddresses
  end
end
