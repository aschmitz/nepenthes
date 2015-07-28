class IpAddressesController < ApplicationController
  before_filter :load_address, only: [:show, :edit, :update, :destroy]
  
  # GET /ip_addresses
  # GET /ip_addresses.json
  def index
    if params[:tag].present?
      @ip_addresses = IpAddress.tagged_with(params[:tag])
    else
      @ip_addresses = IpAddress
    end
    
    @ip_addresses = @ip_addresses.order('address')
    
    respond_to do |format|
      format.html {
        @ip_addresses = @ip_addresses.page(params[:page]).per(50)
      }
      format.json { render json: @ip_addresses }
      format.xml {
        response.headers['Content-Type'] = 'text/xml; charset=UTF-8;'
        response.headers['Content-Disposition'] =
            'attachment; filename=nmap.xml'
        response.stream.write <<-header
<?xml version="1.0"?>
<?xml-stylesheet href="file:///usr/bin/../share/nmap/nmap.xsl"
  type="text/xsl"?>
  <nmaprun scanner="nmap" start="0" startstr="Long ago" version="6.40"
    xmloutputversion="1.04">
  <scaninfo type="connect" protocol="tcp" numservices="65535"
    services="1-65535"/>
  <verbose level="1"/>
  <debugging level="0"/>
        header
        @ip_addresses.includes(:scans).where(scans: {processed: true}
            ).map(&:scans).flatten.each do |scan|
          response.stream.write scan.get_host_xml.to_xml
        end
        response.stream.write '</nmaprun>'
        response.stream.close
      }
      format.text { render text: @ip_addresses.map(&:to_s).join("\n") }
    end
  end
  
  def search
    if @ip_address = IpAddress.find_by_address(NetAddr::CIDR.create(params[:q]).to_i(:ip))
      redirect_to ip_address_url(@ip_address)
    else
      flash[:error] = 'Could not find '+params[:q]
      redirect_to ip_addresses_url
    end
  end

  # GET /ip_addresses/1
  # GET /ip_addresses/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ip_address }
    end
  end

  # GET /ip_addresses/new
  # GET /ip_addresses/new.json
  def new
    @ip_address = IpAddress.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ip_address }
    end
  end

  # GET /ip_addresses/1/edit
  def edit
  end

  # POST /ip_addresses
  # POST /ip_addresses.json
  def create
    @ip_address = IpAddress.new(params[:ip_address])
    
    respond_to do |format|
      if @ip_address.save
        format.html { redirect_to @ip_address, notice: 'Ip address was successfully created.' }
        format.json { render json: @ip_address, status: :created, location: @ip_address }
      else
        format.html { render action: "new" }
        format.json { render json: @ip_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ip_addresses/1
  # PUT /ip_addresses/1.json
  def update
    respond_to do |format|
      if @ip_address.update_attributes(params[:ip_address])
        format.html { redirect_to @ip_address, notice: 'Ip address was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @ip_address.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_addresses/1
  # DELETE /ip_addresses/1.json
  def destroy
    @ip_address.destroy

    respond_to do |format|
      format.html { redirect_to ip_addresses_url }
      format.json { head :no_content }
    end
  end
  
  def batch
    @regions = Region.all
    @region_id = params[:region_id]
    case params[:type] || 'create'
    when 'create'
      @action = 'batch_create'
      @title = 'Add IP Addresses'
    when 'delete'
      @action = 'batch_delete'
      @title = 'Delete IP Addresses'
    else
      render :text => 'Unknown batch action.'
    end
  end

  def batch_create
    # Find me in app/workers/batch_ip_worker.rb
    job_id = BatchIpWorker.perform_async(:create, params)

    flash[:success] = 'Batch job for IP addition started.'
    redirect_to batch_status_ip_addresses_path(:job_id => job_id)
  end

  def batch_delete
    # Find me in app/workers/batch_ip_worker.rb
    job_id = BatchIpWorker.perform_async(:delete, params)

    flash[:success] = 'Batch job for IP delete started.'
    redirect_to batch_status_ip_addresses_path(:job_id => job_id)
  end

  def nate_report
    @port_columns = parse_list(params[:port_columns]) || Port::COMMON_PORTS
    @addresses = IpAddress.with_ports
    respond_to do |format|
      format.html
      format.csv { render text: IpAddress.to_csv(@port_columns) }
    end
  end

  def batch_status
    @job_id = params[:job_id]

    begin
      container = SidekiqStatus::Container.load(params[:job_id])
    rescue SidekiqStatus::Container::StatusNotFound
      @container = nil
    end

    unless container.nil?
      @status = container.status
      @at = container.at
      @total = container.total
      @percent_complete = container.pct_complete
    end
  end
  
  def ranges
    @ranges = NetAddr.merge(IpAddress.all.map(&:to_s), Objectify: true).sort
  end

  private

    def parse_list(str)
      str && str.split(/[, ]+/).map(&:to_i)
    end
    
    def load_address
      # Do we have an actual IP address?
      if params[:id].include?('.')
        @ip_address = IpAddress.find_by_address(
          NetAddr::CIDR.create(params[:id]).to_i(:ip))
      else
        @ip_address = IpAddress.find_by_id(params[:id])
      end
      
      unless @ip_address
        flash[:error] = 'Could not find IP address '+params[:id]
        redirect_to ip_addresses_url
      end
    end
end
