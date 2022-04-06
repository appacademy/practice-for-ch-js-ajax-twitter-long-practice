Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "feed", to: "tweets#feed", as: :feed
  resource :session, only: [:create, :destroy, :new]
  resources :tweets, only: [:create]
  resources :users, only: [:create, :new, :show] do
    get "search", on: :collection
    resource :follow, only: [:create, :destroy]
  end

  root to: redirect("/feed")
end