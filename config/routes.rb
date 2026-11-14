Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessoes#new", as: :login

  if Rails.env.test? || Rails.env.development?
    get "test_login/:id", to: "sessoes#test_login", as: :test_login
  end

  get "admin_login", to: "sessoes_admin#new", as: :admin_login

  resources :estudantes, only: [ :new, :create ] do
    member do
      get :extrato
    end
  end

  get "historico_refeicoes", to: "estudantes#historico", as: :historico_refeicoes

  resources :recargas, only: [ :new, :create, :show ] do
    member do
      patch :confirmar
      patch :expirar
    end
  end

  get "relatorio_global_acessos", to: "relatorios#acessos", as: :relatorio_global_acessos

  get "/cardapio/atual", to: "cardapios#atual", as: "cardapio_atual"

  get "/catraca/validacao", to: "acessos#new", as: "catraca_validacao"
  post "/catraca/validacao", to: "acessos#create"
  post "/catraca/sincronizar", to: "acessos#sincronizar"

  # Defines the root path route ("/")
  # root "cardapios#atual"
end
