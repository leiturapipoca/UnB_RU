ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __dir__)

require "rspec/expectations"
require "capybara/rails"
require "capybara/cucumber"
require 'cucumber/rails'
require "active_support/testing/time_helpers"

# Disponibiliza new_estudante_path, login_path e demais rotas nos steps
World(Rails.application.routes.url_helpers)
# Permite travel_to / travel_back para simular horários
World(ActiveSupport::Testing::TimeHelpers)

# Limpa os dados de teste antes E depois de cada cenário (assim o RSpec, que roda
# depois, também encontra o banco vazio).
# TRUNCATE não dispara o gatilho de imutabilidade de "acessos" (delete_all dispararia);
# o CASCADE limpa também as tabelas que dependem dessas.
LIMPAR_BANCO = "TRUNCATE campi, funcionarios, grupos_tarifarios, estudantes RESTART IDENTITY CASCADE"

Before do
  ActiveRecord::Base.connection.execute(LIMPAR_BANCO)
end

After do
  travel_back
  ActiveRecord::Base.connection.execute(LIMPAR_BANCO)
end
