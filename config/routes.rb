Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
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
