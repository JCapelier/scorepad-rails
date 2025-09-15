class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :session_players, dependent: :destroy
  has_many :game_sessions, through: :session_players

  has_one_attached :avatar

  validates :username, presence: { message: "Username can't be blank" }
  validates :username, uniqueness: { case_sensitive: false, message: "Username is already taken" }
  validates :username, length: { minimum: 3, maximum: 20, message: "Username must be between 3 and 20 characters" }
  validates :username, format: { with: /\A[^\s]+\z/, message: "Username cannot contain spaces" }

  validates :first_name, presence: { message: "First name can't be blank" }, length: { maximum: 30, message: "First name is too long (max 30 characters)" }
  validates :last_name, presence: { message: "Last name can't be blank" }, length: { maximum: 30, message: "Last name is too long (max 30 characters)" }
  validates :email, presence: { message: "Email can't be blank" }, uniqueness: { case_sensitive: false, message: "Email is already taken" }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Email format is invalid" }
  validates :password, presence: { message: "Password can't be blank" }, length: { minimum: 6, message: "Password must be at least 6 characters" }, if: :password_required?

  private

  def password_required?
    new_record? || password.present?
  end

  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      ActionController::Base.helpers.asset_path("default-avatar.jpg")
    end
  end
end
