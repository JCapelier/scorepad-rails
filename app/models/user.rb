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

  validates :email, presence: { message: "Email can't be blank" }, uniqueness: { case_sensitive: false, message: "Email is already taken" }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Email format is invalid" }
  validates :password, presence: { message: "Password can't be blank" }, length: { minimum: 6, message: "Password must be at least 6 characters" }, if: :password_required?

  before_create :generate_confirmation_token

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
    self.confirmation_sent_at = Time.current
  end

  def confirm!
    update(confirmed_at: Time.current, confirmation_token: nil)
  end

  def confirmed?
    confirmed_at.present?
  end

  def resend_confirmation!
    generate_confirmation_token
    save!
    # You can trigger the mailer here if you want
  end

  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      ActionController::Base.helpers.asset_path("default-avatar.jpg")
    end
  end

  private

  def password_required?
    new_record? || password.present?
  end
end
