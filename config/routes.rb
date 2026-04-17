Rails.application.routes.draw do
  resources :tasks
  resources :deadlines
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

  root "legal_cases#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
