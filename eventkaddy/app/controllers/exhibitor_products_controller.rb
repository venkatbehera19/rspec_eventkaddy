class ExhibitorProductsController < ApplicationController
  layout :set_layout
  include ExhibitorPortalsHelper

  def index
    unless params[:exhibitor_id].blank?
      session[:exhibitor_id_portal] = params[:exhibitor_id]
    end
    @exhibitor          = get_exhibitor
    @exhibitor && check_for_payment
    @current_tab        = Tab.tab_by_event_and_default_name session[:event_id], "Exhibitor Product", 'exhibitor'
    @exhibitor_products = ExhibitorProduct.where(event_id:session[:event_id],exhibitor_id:@exhibitor.id)
  end

  def show
    @exhibitor_product = ExhibitorProduct.find(params[:id])
    @exhibitor         = @exhibitor_product.exhibitor

    render :layout => false
  end

  def new
    @exhibitor_product = ExhibitorProduct.new
    # @exhibitor_id      = get_exhibitor.id
  end

  def edit
    @exhibitor_product = ExhibitorProduct.find(params[:id])
    # @exhibitor_id      = @exhibitor_product.exhibitor_id
  end

  def create
    @exhibitor_product              = ExhibitorProduct.new(exhibitor_product_params)
    @exhibitor_product.exhibitor_id = get_exhibitor.id
    @exhibitor_product.event_id     = session[:event_id]

    @exhibitor_product.updateProductImage(params)

    respond_to do |format|
      if @exhibitor_product.save && @exhibitor_product.generate_qr_image
        format.html { redirect_to("/exhibitor_products/", :notice => 'Exhibitor Product was successfully created.') }
        # format.xml  { render :xml => @exhibitor_product, :status => :created, :location => @exhibitor_product }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @exhibitor_product.errors, :status => :unprocessable_entity }
      end
    end

  end

  def update
    @exhibitor_product = ExhibitorProduct.find(params[:id])
    @exhibitor_product.updateProductImage(params)

    respond_to do |format|
      if @exhibitor_product.update!(exhibitor_product_params)
        format.html { redirect_to("/exhibitor_products", :notice => 'Exhibitor Product was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @exhibitor_product.errors, :status => :unprocessable_entity }
      end
    end
  end


  def destroy
    @exhibitor_product = ExhibitorProduct.find(params[:id])
    @exhibitor_product.destroy

    respond_to do |format|
        format.html { redirect_to("/exhibitor_products", :notice => 'Exhibitor Product successfully deleted.') }
    end

  end

  private

  def get_exhibitor
    if current_user.role? :exhibitor then
      if current_user.is_a_staff?
        es = ExhibitorStaff.find_by_user_id current_user.id
        return Exhibitor.find es.exhibitor_id
      else
        current_user.first_or_create_exhibitor( session[:event_id] )
      end
    elsif !session[:exhibitor_id_portal].blank?
      puts "test: #{session[:exhibitor_id_portal]}"
      Exhibitor.find(session[:exhibitor_id_portal])
    end
  end

  def set_layout
    if current_user.role? :exhibitor then
      'exhibitorportal'
    else
      'subevent_2013'
    end
  end

  private

  def exhibitor_product_params
    params.require(:exhibitor_product).permit(:event_id, :exhibitor_id, :qr_code_id, :product_image_id, :name, :description, :qr_content, :product_url, :youtube_url)
  end

end
