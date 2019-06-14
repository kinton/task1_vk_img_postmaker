class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # GET /posts
  # GET /posts.json
  def index
    #@posts = Post.all
    @posts = Post.order('created_at DESC')
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    require 'net/http'
    require 'net/https'
    require 'uri'
    require 'json'

    begin
      group_id = @post.groupId
      parameters = {"v" => "5.95", "access_token" => @post.token}

      url = "https://api.vk.com/method/photos.getWallUploadServer?group_id=" + group_id.to_s
      serverInfo = make_request(url, parameters)

      uri = URI.parse serverInfo["upload_url"]
      connection = Net::HTTP.new uri.host, uri.port
      connection.use_ssl = true
      request = Net::HTTP::Post.new uri
      form_data = [
        ['photo',  File.open(@post.image.current_path)]
      ]
      request.set_form form_data, 'multipart/form-data'
      @response = connection.request request
      photoInfo = JSON.parse(@response.body)

      url = "https://api.vk.com/method/photos.saveWallPhoto?group_id=" + group_id.to_s + "&server=" + photoInfo["server"].to_s + "&photo=" + photoInfo["photo"].to_s + "&hash=" + photoInfo["hash"].to_s
      uploadedPhotoInfo = make_request(url, parameters)

      if @post.descriprion != ""
        url = "https://api.vk.com/method/wall.post?owner_id=-" + group_id.to_s + "&from_group=1&message=" + @post.descriprion.to_s + "&attachments=photo" + uploadedPhotoInfo[0]["owner_id"].to_s + "_" + uploadedPhotoInfo[0]["id"].to_s
      else
        url = "https://api.vk.com/method/wall.post?owner_id=-" + group_id.to_s + "&from_group=1&attachments=photo" + uploadedPhotoInfo[0]["owner_id"].to_s + "_" + uploadedPhotoInfo[0]["id"].to_s
      end
      post = make_request(url, parameters)

      @info = "https://vk.com/clash_attack?w=wall-" + group_id.to_s + "_" + post["post_id"].to_s
    rescue Exception => e
      @info = "We have some errors, sorry!"
      print e
    end

  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    if @post.save
      puts @post.token
      redirect_to post_path(@post)
    else
      render :new
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    if @post.update_attributes(post_params)
      redirect_to post_path(@post)
    else
      render :edit
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:image, :descriprion, :token, :groupId, :remove_image)
    end

    def make_request(url, parameters)
      uri = URI.parse(url)
      @response = Net::HTTP.post_form(uri, parameters)
      return JSON.parse(@response.body)["response"]
    end
end
