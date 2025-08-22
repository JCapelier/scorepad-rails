class SessionPlayer < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :game_session
  has_many :moves, dependent: :destroy

  def display_name
    user ? user.username : guest_name
  end
end
