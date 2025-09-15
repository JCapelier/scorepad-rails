class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]
  def home
    authorize :page, :home?
    @user = current_user
    @games = Game.all
  end
end
