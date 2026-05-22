Rails.application.routes.draw do
  resource :session, only: [:new, :create, :destroy]
  resources :passwords, param: :token, only: [:new, :create, :edit, :update]

  # Registration
  resources :registrations, only: [:new, :create]
  get "confirm/:token", to: "registrations#confirm", as: :confirm_registration

  # Main pages
  root "home#index"
  get "dashboard", to: "dashboard#index"
  resource :settings, only: [:show, :update]
  get "upgrade", to: "upgrade#show"

  # Webhooks
  post "webhooks/lemonsqueezy", to: "webhooks#lemonsqueezy"

  get "up" => "rails/health#show", as: :rails_health_check
end
