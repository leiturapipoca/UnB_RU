Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Tela principal da aplicação de controle (exige funcionário logado)
  root "painel#index"
  get "login", to: "sessoes#new", as: :login
  post   "login",  to: "sessoes#create"
  delete "logout", to: "sessoes#destroy", as: :logout

 if Rails.env.test? || Rails.env.development?
    get "test_login/:id", to: "sessoes#test_login", as: :test_login
    get "test_login_funcionario/:id", to: "sessoes#test_login_funcionario", as: :test_login_funcionario
  end
  
  get "admin_login", to: "sessoes_admin#new", as: :admin_login

  resources :estudantes, only: [ :new, :create ] do
    member do
      get :extrato
    end
  end

  get "historico_refeicoes", to: "estudantes#historico", as: :historico_refeicoes
  post "historico_refeicoes/exportar", to: "estudantes#exportar_historico", as: :exportar_historico_refeicoes

  resources :recargas, only: [ :new, :create, :show ] do
    member do
      patch :confirmar
      patch :expirar
    end
  end

  get "relatorio_global_acessos", to: "relatorios#acessos", as: :relatorio_global_acessos

  # Relatórios de Operação em PDF (Gestor)
  resources :relatorios, only: [ :index ] do
    collection do
      get :exportar
    end
  end

  get "/cardapio/atual", to: "cardapios#atual", as: "cardapio_atual"

  resources :restaurantes, except: :show

  # Gestão de Turnos
  resources :turnos, only: [ :new, :create ]

  # Issue 5: escolha do restaurante/catraca depois do login
  get  "ponto-de-acesso", to: "ponto_acesso#new",    as: :ponto_acesso
  post "ponto-de-acesso", to: "ponto_acesso#create"

  # Validação de entrada comum (matrícula), modo offline e sincronização da catraca
  get  "/catraca/validacao",   to: "acessos#new",            as: "catraca_validacao"
  post "/catraca/validacao",   to: "acessos#create"
  post "/catraca/offline",     to: "acessos#ativar_offline", as: "catraca_offline"
  post "/catraca/sincronizar", to: "acessos#sincronizar",    as: "catraca_sincronizar"

  # Issue 16: leitura do passe do FastPass na catraca
  get  "/catraca/fastpass", to: "fastpass#new", as: :fastpass
  post "/catraca/fastpass", to: "fastpass#create"

  get  "inscricoes_fastpass",      to: "inscricoes_fastpass#index",  as: :inscricoes_fastpass
  get  "inscricoes_fastpass/nova", to: "inscricoes_fastpass#new",    as: :nova_inscricao_fastpass
  post "inscricoes_fastpass",      to: "inscricoes_fastpass#create"
end
