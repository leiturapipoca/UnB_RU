ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __dir__)

require "rspec/expectations"
require "capybara/rails"
require "capybara/cucumber"
require 'cucumber/rails'
# Disponibiliza new_estudante_path e demais rotas nos steps
World(Rails.application.routes.url_helpers)

# Limpa os dados de teste antes de cada cenário respeitando a ordem das chaves estrangeiras
Before do
  # 1. Apaga a tabela Acesso usando TRUNCATE para burlar a trigger de imutabilidade no ambiente de teste
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE acessos CASCADE")
  
  # 2. Apaga as demais tabelas filhas
  SessaoOperacao.delete_all
  Turno.delete_all
  Tarifa.delete_all
  
  # 3. Apaga a infraestrutura
  Catraca.delete_all
  Restaurante.delete_all
  Campus.delete_all
  Funcionario.delete_all

  # 4. Apaga dados financeiros e usuários
  Recarga.delete_all
  Estudante.delete_all
  GrupoTarifario.delete_all
end