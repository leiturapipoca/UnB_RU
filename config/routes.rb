Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Tela principal da aplicação de controle (exige funcionário logado)
  root "painel#index"

  # Estudante: cadastro e extrato
  resources :estudantes, only: [ :new, :create ] do
    member do
      get :extrato
    end
  end

  # Cardápio da refeição atual
  get "/cardapio/atual", to: "cardapios#atual", as: "cardapio_atual"

  # Issue 4: autenticação do funcionário (get "login" também é o destino de quem não está logado)
  get    "login",  to: "sessoes#new",     as: :login
  post   "login",  to: "sessoes#create"
  delete "logout", to: "sessoes#destroy", as: :logout

  # Atalho para os testes do extrato: entra como estudante (só em test/development)
  if Rails.env.test? || Rails.env.development?
    get "test_login/:id", to: "sessoes#test_login", as: :test_login
  end

  # Issue 8: gestão de restaurantes e catracas (administrador)
  resources :restaurantes, except: :show

  # Issue 5: escolha do restaurante/catraca depois do login
  get  "ponto-de-acesso", to: "ponto_acesso#new",    as: :ponto_acesso
  post "ponto-de-acesso", to: "ponto_acesso#create"

  # Validação de entrada comum (matrícula) e sincronização offline da catraca
  get  "/catraca/validacao",  to: "acessos#new",        as: "catraca_validacao"
  post "/catraca/validacao",  to: "acessos#create"
  post "/catraca/sincronizar", to: "acessos#sincronizar"

  # Issue 16: leitura do passe do FastPass na catraca
  get  "/catraca/fastpass", to: "fastpass#new", as: :fastpass
  post "/catraca/fastpass", to: "fastpass#create"
end
