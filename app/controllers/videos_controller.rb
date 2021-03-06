class VideosController < ApplicationController
  before_action :ensure_admin, :except => [:index, :show]

  def index
    @videos = Video.list_for(current_user).page(params[:page])

    respond_to do |format|
      format.html
      format.atom { render :layout => false }
    end
  end

  def show
    @video = Video.friendly.find(params[:id])

    ensure_admin if @video.draft?
  end

  def new
    @form = Videos::Form.new
  end

  def create
    @form = Videos::CreateForm.build_from(:video, params, :user => current_user)

    Videos::Create.call(@form)
      .on(:ok) { redirect_to videos_path, :notice => t(:created_video) }
      .on(:fail) { render :new }
  end

  def edit
    @form = Videos::Form.build_from(:video, params)
    video = Video.friendly.find(@form.id)

    AutoMapper.new(video).map_to(@form)
  end

  def update
    @form = Videos::Form.build_from(:video, params)

    Videos::Update.call(@form)
      .on(:ok) { redirect_to videos_path, :notice => t(:updated_video) }
      .on(:fail) { render :edit }
  end
end
