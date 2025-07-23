Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :users, only: [:show]
  resources :games, only: [:show] do
    resources :game_sessions, only: [:new]
  end
  resources :game_sessions, only: [:update]
end
