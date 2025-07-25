Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :users, only: [:show]

  resources :game_sessions, only: [:create] do
    member do
      get :seating, as: :seating
      patch :assign_seats, as: :assign_seats
    end
  end

  resources :games, only: [:show]
  resources :game_sessions, only: [:update]
end
