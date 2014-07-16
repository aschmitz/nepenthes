class PortsController < ApplicationController
  def index
    if params[:tag].present?
      @ports = Port.tagged_with(params[:tag])
    else
      @ports = Port
    end
    
    @ports = @ports.order('number')
    @unique_ports = @ports.group('number')
    
    @output_array = Array.new
    @unique_ports.each { |p|
      data = Hash.new
      data[:number] = p.number
      data[:count] = @ports.where("number = ?",p.number).count
      data[:done] = @ports.where("number = ?",p.number).count(:done)
      @output_array << data
    }
    
    respond_to do |format|
      format.html { @output_array }
      format.json { render json: @ports }
      format.text { render text:
          Port.order('number').group('number').map(&:number).join("\n") }
      format.csv { render text: Port.order('number').includes(:ip_address).to_csv }
    end
  end

  # GET /ip_addresses/1
  # GET /ip_addresses/1.json
  def show
    if params[:tag].present?
      @ports = Port.tagged_with(params[:tag])
    else
      @ports = Port
    end
    
    if params[:todo].present?
      @ports = @ports.where(:number => params[:id]).where("ports.done IS NULL or ports.done = 0").includes(:ip_address).order('ip_addresses.address').page(params[:page]).per(50)
    else
      @ports = @ports.where(:number => params[:id]).includes(:ip_address).order('ip_addresses.address').page(params[:page]).per(50)
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ports }
      format.text { render text: @ports.all.map{ |p|
          p.ip_address.to_s }.join("\n") }
      format.csv { render text: @ports.to_csv }
    end
  end
  
  def update
    @port = Port.find(params[:id])
    
    respond_to do |format|
      if @port.update_attributes(params[:port])
        if params[:todo].present?
          format.html { redirect_to :back, notice: 'Port was updated sucessfully.' }
        else
          format.html { redirect_to :back, notice: 'Port was updated sucessfully.' }
        end
      else
        format.html { render action: "edit" }
      end
    end
  end
  
  def edit
    @port = Port.find(params[:id])
  end
  
  def mark_as_done
    @port = Port.find(params[:id])
    @port.done = @port.done ? nil : true
    @port.save!
    if params[:todo].present?
      redirect_to :back, notice: 'Port marked as done.'
    else
      redirect_to :back, notice: 'Port marked as done.'
    end
  end
end
