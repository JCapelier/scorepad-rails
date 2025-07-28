class UsersController < ApplicationController
  def autocomplete
    input = params[:input].to_s.strip
    if input.length < 2
      render json: []
    else
      usernames = User.where("unaccent(username) ILIKE unaccent(?)", "%#{input}%").limit(10)
      render json: usernames.map { |user| { id: user.id, username: user.username, avatar_url: user.avatar_url } }
    end
  end
end
