Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  resources :estudantes, only: [:new, :create]

  Rails.application.routes.draw do
    get '/cardapio/atual', to: 'cardapios#atual', as: 'cardapio_atual'
  end

  Rails.application.routes.draw do
    resources :estudantes, only: [:new, :create] do
      member do
        get :extrato
      end
    end

    get 'login', to: 'sessoes#new', as: :login

    if Rails.env.test? || Rails.env.development?
      get 'test_login/:id', to: 'sessoes#test_login', as: :test_login
    end

    get '/catraca/validacao', to: 'acessos#new', as: 'catraca_validacao'
    post '/catraca/validacao', to: 'acessos#create'
    post '/catraca/sincronizar', to: 'acessos#sincronizar'
  end
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end