Rails.application.routes.draw do
  devise_for :users
  get 'users/autocomplete', to: 'users#autocomplete'
  root to: "pages#home"

  resources :users, only: [:show]
  resources :games, only: [:show]
  resources :game_sessions, only: [:new, :create, :update]
  resources :scoresheets, only: [:show, :update] do
    member do
      get :results
    end
  end
  resources :rounds, only: [:update]
end
