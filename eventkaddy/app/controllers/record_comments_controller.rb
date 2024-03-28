class RecordCommentsController < ApplicationController
  # GET /record_comments
  # GET /record_comments.xml
  
  load_and_authorize_resource
  
  def index
    @record_comments = RecordComment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @record_comments }
    end
  end

  # GET /record_comments/1
  # GET /record_comments/1.xml
  def show
    @record_comment = RecordComment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @record_comment }
    end
  end

  # GET /record_comments/new
  # GET /record_comments/new.xml
  def new
    @record_comment = RecordComment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @record_comment }
    end
  end

  # GET /record_comments/1/edit
  def edit
    @record_comment = RecordComment.find(params[:id])
  end

  # POST /record_comments
  # POST /record_comments.xml
  def create
    @record_comment = RecordComment.new(record_comment_params)

    respond_to do |format|
      if @record_comment.save
        format.html { redirect_to(@record_comment, :notice => 'Record comment was successfully created.') }
        format.xml  { render :xml => @record_comment, :status => :created, :location => @record_comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @record_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /record_comments/1
  # PUT /record_comments/1.xml
  def update
    @record_comment = RecordComment.find(params[:id])

    respond_to do |format|
      if @record_comment.update!(record_comment_params)
        format.html { redirect_to(@record_comment, :notice => 'Record comment was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @record_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /record_comments/1
  # DELETE /record_comments/1.xml
  def destroy
    @record_comment = RecordComment.find(params[:id])
    @record_comment.destroy

    respond_to do |format|
      format.html { redirect_to(record_comments_url) }
      format.xml  { head :ok }
    end
  end

  private

  def record_comment_params
    params.require(:record_comment).permit(:comment, :user_id, :record_id)
  end

end