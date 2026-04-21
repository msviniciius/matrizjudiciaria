Rails.application.routes.draw do
  get "/painel", to: "dashboard#index"
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  get "/logout", to: "sessions#destroy"
  resource :office_setting, only: %i[show edit update] do
    resources :users, controller: "office_users", except: :show
  end

  resources :tasks
  resources :deadlines do
    member do
      patch :quick_update
    end
  end
  resources :deadline_settings, except: :show
  resources :case_events
  resources :movement_types
  resources :movement_templates
  resources :process_movements

  resources :legal_cases do
    collection do
      get :daily_closure
    end

    member do
      get :calendar
    end

    resources :process_exams, only: [ :new, :create ]
  end

  resources :process_exams, only: [ :edit, :update, :destroy ]
  resources :clients do
    collection do
      post :quick_create
    end
  end
  resources :courts
  resources :districts, only: [] do
    resources :courts_lookup, only: :index
  end
  resources :districts

  resources :legal_areas, only: [] do
    resources :process_types, only: :index
  end

  root "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
