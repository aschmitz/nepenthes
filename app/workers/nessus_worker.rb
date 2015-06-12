require 'rest-client'

class NessusWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'nessus'
  
  BASEURL = 'https://127.0.0.1:8834'
  USERNAME = ''
  PASSWORD = ''
  
  def safe_request(method, path, opts, payload = nil)
    tries = 0
    begin
      tries += 1
      res = RestClient::Request.execute(
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        headers: opts[:headers],
        method: method,
        url: "#{opts[:baseurl]}#{path}",
        payload: payload)
    rescue RestClient::RequestTimeout => e
      retry if tries < 5
    rescue Exception => e
      p "======  Error!  ======"
      p e.class
      p e
      p res.body
      throw e
    end
    
    if res == nil
      p "======  Nil!  ======"
      p res.body
    end
    
    return res
  end
  
  def perform(ip_id, base_policy_id)
    ip = IpAddress.find(ip_id)
    baseurl = BASEURL
    username = USERNAME
    password = PASSWORD
    req_opts = { baseurl: baseurl }
    have_policy = false
    have_scan = false
    
    token = JSON.parse(safe_request(:post, "/session", req_opts, {
        username: username,
        password: password
      }))['token']
    req_opts[:headers] = {
      'X-Cookie' => "token=#{token}",
      'Content-Type' => 'application/json'
    }
    
    begin
      policy_id = JSON.parse(safe_request(:post,
        "/policies/#{base_policy_id}/copy", req_opts, ''))['id']
      have_policy = true
      
      # The copy action doesn't return the UUID, so we have to get it separately.
      policy_copy = JSON.parse(safe_request(:get, "/policies/#{policy_id}",
        req_opts))
      policy_uuid = policy_copy['uuid']
      policy_name = policy_copy['settings']['name']+": Nepenthes Copy for "+
        ip.to_s
      
      # Set the appropriate list of ports
      safe_request(:put, "/policies/#{policy_id}", req_opts, {
          uuid: policy_uuid,
          settings: {
            name: policy_name,
            portscan_range: ip.ports.map(&:number).map(&:to_s).join(',')
          }
        }.to_json)
      
      # Create the scan.
      scan = JSON.parse(safe_request(:post, '/scans', req_opts, {
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
        req_opts, ''))
      
      # Check for status
      status = 'running'
      
      while ['running', 'processing'].include?(status)
        sleep 10
        scan = JSON.parse(safe_request(:get, "/scans/#{scan_id}", req_opts))
        status = scan['info']['status']
        p status
      end
      
      host_id = scan['hosts'][0]['host_id']
      plugins = scan['vulnerabilities'].map{|v| v['plugin_id']}
      
      plugins.each do |plugin_id|
        plugin_results = JSON.parse(safe_request(:get,
          "/scans/#{scan_id}/hosts/#{host_id}/plugins/#{plugin_id}", req_opts))
        
        plugin = NessusPlugin.where(id: plugin_id).first_or_create do |plugin|
          plugin.name = plugin_results['info']['plugindescription']['pluginname']
          plugin.severity = plugin_results['info']['plugindescription']['severity']
        end
        plugin.extra = plugin_results['info']['plugindescription']['pluginattributes']
        plugin.save
        
        ip.nessus_results.where(nessus_plugin_id: plugin_id).delete_all
        
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
      ip.has_nessus = true
      ip.save
    ensure
      if have_scan
        # Delete the scan.
        safe_request(:delete, "/scans/#{scan_id}", req_opts, '')
      end
      
      if have_policy
        # Delete the policy.
        safe_request(:delete, "/policies/#{policy_id}", req_opts, '')
      end
    end
  end
end
