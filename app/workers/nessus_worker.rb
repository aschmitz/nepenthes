require 'rest-client'

class NessusWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'nessus'
  
  BASEURL = 'https://127.0.0.1:8834'
  USERNAME = ''
  PASSWORD = ''
  
  def safe_request(method, path, payload = nil)
    tries = 0
    begin
      tries += 1
      res = RestClient::Request.execute(
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        headers: @req_opts[:headers],
        method: method,
        url: "#{@req_opts[:baseurl]}#{path}",
        payload: payload,
        timeout: 10,
        open_timeout: 10)
      if res == nil
        p "======  Nil!  ======"
        p [method, path]
        raise EOFError # So we can retry more cleanly
      end
    rescue RestClient::RequestTimeout, EOFError => e
      retry if tries < 5
    rescue RestClient::Unauthorized => e
      if tries < 5
        login
        retry
      end
    rescue Exception => e
      p "======  Error!  ======"
      p e.class
      p e
      p e.response.body
      throw e
    end
    
    return res
  end
  
  def login
    token = JSON.parse(safe_request(:post, "/session", {
        username: USERNAME,
        password: PASSWORD,
      }))['token']
    @req_opts[:headers] = {
      'X-Cookie' => "token=#{token}",
      'Content-Type' => 'application/json'
    }
  end
  
  def perform(ip_id, base_policy_id)
    ip = IpAddress.find(ip_id)
    @req_opts = { baseurl: BASEURL }
    have_policy = false
    have_scan = false
    
    begin
      policy_id = JSON.parse(safe_request(:post,
        "/policies/#{base_policy_id}/copy", ''))['id']
      have_policy = true
      
      # The copy action doesn't return the UUID, so we have to get it separately.
      policy_copy = JSON.parse(safe_request(:get, "/policies/#{policy_id}"))
      policy_uuid = policy_copy['uuid']
      policy_name = policy_copy['settings']['name']+": Nepenthes Copy for "+
        ip.to_s
      
      # Set the appropriate list of ports
      safe_request(:put, "/policies/#{policy_id}", {
          uuid: policy_uuid,
          settings: {
            name: policy_name,
            portscan_range: ip.ports.map(&:number).map(&:to_s).join(',')
          }
        }.to_json)
      
      # Create the scan.
      scan = JSON.parse(safe_request(:post, '/scans', {
          uuid: policy_uuid,
          settings: {
            name: 'Nepenthes Scan: '+ip.to_s,
            enabled: false,
            policy_id: policy_id,
            text_targets: ip.to_s,
            use_dashboard: false,
          }
        }.to_json))['scan']
      have_scan = true
      
      # Launch the scan
      scan_id = scan['id']
      launch_results = JSON.parse(safe_request(:post, "/scans/#{scan_id}/launch",
        ''))
      
      # Check for status
      status = 'running'
      
      while ['running', 'processing'].include?(status)
        sleep 10
        scan = JSON.parse(safe_request(:get, "/scans/#{scan_id}"))
        status = scan['info']['status']
        p status
      end
      
      begin
        host_id = scan['hosts'].detect{|h| h['hostname'] == ip.to_s}['host_id']
      rescue NoMethodError => e
        # We'll get NoMethodError: undefined method `[]' for nil:NilClass if the
        # host didn't show up in the Nessus results for some reason. This can
        # happen when the ports we had aren't open any longer, which might
        # happen if the host goes down, or is transient for whatever reason. In
        # this case, we'll just say that we have nessus results and end.
        host_id = nil
      end
      
      if host_id != nil
        plugins = scan['vulnerabilities'].map{|v| v['plugin_id']}
        
        plugins.each do |plugin_id|
          plugin_results = JSON.parse(safe_request(:get,
            "/scans/#{scan_id}/hosts/#{host_id}/plugins/#{plugin_id}"))
          
          next if plugin_results['outputs'].blank?
          
          plugin = NessusPlugin.where(id: plugin_id).first_or_create do |plugin|
            plugin.name = plugin_results['info']['plugindescription']['pluginname']
            plugin.severity = plugin_results['info']['plugindescription']['severity']
          end
          plugin.extra = plugin_results['info']['plugindescription']['pluginattributes']
          plugin.save
          
          ip.nessus_results.where(nessus_plugin_id: plugin_id).destroy_all
          
          plugin_results['outputs'].each do |output|
            # This should probably look up ports and link them somehow.
            result = ip.nessus_results.create(
              nessus_plugin_id: plugin_id,
              ports: output['ports'],
              output: output['plugin_output'],
              severity: output['severity'],
            )
          end
        end
      end
      ip.has_nessus = true
      ip.save
    ensure
      if have_scan
        # Delete the scan.
        safe_request(:delete, "/scans/#{scan_id}", '')
      end
      
      if have_policy
        # Delete the policy.
        safe_request(:delete, "/policies/#{policy_id}", '')
      end
    end
  end
end
