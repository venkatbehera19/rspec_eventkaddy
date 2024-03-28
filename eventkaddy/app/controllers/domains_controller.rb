class DomainsController < ApplicationController
  layout 'subevent_2013'
  load_and_authorize_resource
  
  def index
    @domains = Domain.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @domains }
    end
  end

  def new
    @domain = Domain.new
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @domain}
    end
  end

  def edit
    @domain = Domain.find(params[:id])
  end

  def create
    @domain = Domain.create(domain_params)

    respond_to do |format|
        format.html { redirect_to domains_path }
    end
  end

  def update
    @domain = Domain.find(params[:id])

    respond_to do |format|
      if @domain.update!(domain_params)
        format.html { redirect_to domains_path, :notice => 'Domain was successfully updated.'}
        format.xml  { head :ok }
      end
    end
  end

  def destroy
    @domain = Domain.find(params[:id])
    @domain.destroy

    respond_to do |format|
      format.html { redirect_to domains_path }
      format.xml  { head :ok }
    end
  end

  private

  def domain_params
    params.require(:domain).permit(:event_id, :domain_type_id, :domain, :subdomain)
  end

end