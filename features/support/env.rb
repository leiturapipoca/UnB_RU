ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __dir__)

require "rspec/expectations"
require "capybara/rails"
require "capybara/cucumber"
require 'cucumber/rails'
# Disponibiliza new_estudante_path e demais rotas nos steps
World(Rails.application.routes.url_helpers)

# Limpa os dados de teste antes de cada cenário
Before do
  Recarga.delete_all
  Estudante.delete_all
  GrupoTarifario.delete_all
end