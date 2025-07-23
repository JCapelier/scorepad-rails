class SessionPlayer < ApplicationRecord
  belongs_to :user
  belongs_to :game_session
  has_many :moves, dependent: :destroy
end
