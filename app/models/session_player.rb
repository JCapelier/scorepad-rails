class SessionPlayer < ApplicationRecord
  validates :guest_name, presence: { message: "Guest name can't be blank" }, format: { with: /\A[^\s]+\z/, message: "Guest name cannot contain spaces" }, allow_nil: true
  belongs_to :user, optional: true
  belongs_to :game_session
  has_many :moves, dependent: :destroy

  def display_name
    user ? user.username : guest_name
  end
end
