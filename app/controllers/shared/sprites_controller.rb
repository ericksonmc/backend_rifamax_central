class Shared::SpritesController < ApplicationController
  before_action :authorize_request, except: %i[index]

  # GET /shared/sprites?asset={identifier}
  def index
    @shared_sprites = Shared::Sprite.get_sprite(params[:asset])

    if @shared_sprites
      render json: @shared_sprites, status: :ok
    else
      render json: { message: 'Sprite is not found' }, status: :not_found
    end
  end

  # POST /shared/sprites
  def create
    @shared_sprites = Shared::Sprite.new(shared_sprite_params)
    if @shared_sprites.save
      render json: @shared_sprites, status: :created, location: @shared_sprites
    else
      render json: @shared_sprites.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /shared/sprites
  def update
    if @shared_sprite.update(shared_printer_params)
      render json: @shared_sprite
    else
      render json: @shared_sprite.errors, status: :unprocessable_entity
    end
  end

  # DELETE /shared/sprites
  def destroy
    @shared_sprite.destroy
  end

  private

  def set_shared_sprite
    @shared_sprite = Shared::Sprite.find_by(identifier: params[:asset])
  end

  def shared_sprite_params
    params.require(:sprite).permit(
      :asset,
      :each_width,
      :each_height,
      :height,
      :width
      :identifier
    )
  end
end
