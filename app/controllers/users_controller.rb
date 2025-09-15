class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user
    @stats = Users::UserStatsService.new(@user)
  end

  def autocomplete
    user = current_user
    authorize user
    input = params[:input].to_s.strip
    if input.length < 2
      render json: []
    else
      usernames = User.where("unaccent(username) ILIKE unaccent(?)", "%#{input}%").limit(10)
      render json: usernames.map { |user| { id: user.id, username: user.username, avatar_url: user.avatar_url } }
    end
  end

  def update
    @user = current_user
    authorize @user
    # Handle password update
    if params[:user][:current_password].present? || params[:user][:password].present?
      if @user.update_with_password(password_params)
        bypass_sign_in(@user) # Devise: keep user signed in after password change
        flash[:notice] = "Password updated successfully."
        redirect_to settings_user_path(@user)
        return
      else
        flash.now[:alert] = "Could not update password."
        render :settings, status: :unprocessable_entity
        return
      end
    end

    # Handle avatar and username update
    if @user.update(user_params)
      flash[:notice] = "Account updated successfully."
      redirect_to settings_user_path(@user)
    else
      flash.now[:alert] = "Could not update account."
      render :settings, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :avatar)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
