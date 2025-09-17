Rails.application.routes.draw do
  namespace :admin do
      resources :games
      resources :game_sessions
      resources :moves
      resources :rounds
      resources :scoresheets
      resources :session_players
      resources :users

      root to: "games#index"
    end

  devise_for :users
  get 'users/autocomplete', to: 'users#autocomplete'
  root to: "pages#home"

  resources :users, only: [:show, :update] do
    get :settings, on: :member
  end
  resources :games, only: [:show]
  resources :game_sessions, only: [:new, :create, :update, :destroy]
  resources :scoresheets, only: [:show, :update] do
      get :results, on: :member
  end
  resources :rounds, only: [:update]
end
