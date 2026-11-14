# frozen_string_literal: true

# features/step_definitions/historico_estudante_steps.rb

Dado(/^que o estudante acessa a página de "([^"]*)"$/) do |_pagina|
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I', descricao: 'Isento')
  @estudante = Estudante.find_or_create_by!(matricula: '242001508') do |e|
    e.nome = 'Guilherme Silva Cavalcante'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end

  visit login_path
  fill_in 'Matrícula', with: @estudante.matricula
  fill_in 'Senha', with: 'senha_segura_123'
  click_button 'Entrar'
  visit historico_refeicoes_path
end

Dado(/^possui registros de refeições no mês atual$/) do
  Refeicao.create!(
    estudante: @estudante,
    turno: 'Almoço',
    valor: 0.0,
    data: Date.current
  )
  visit historico_refeicoes_path
end

Quando(/^ele clica no botão "([^"]*)"$/) do |botao|
  click_button botao
end

Quando(/^seleciona o formato "([^"]*)"$/) do |formato|
  select formato, from: 'Formato'
  click_button 'Confirmar Exportação'
end

Então(/^o sistema deve fazer o download de um arquivo chamado "([^"]*)"$/) do |nome_arquivo|
  expect(page.response_headers['Content-Type']).to include('application/pdf')
  expect(page.response_headers['Content-Disposition']).to include("filename=\"#{nome_arquivo}\"")
end

Dado(/^que o estudante acessou o histórico sem nenhuma refeição registrada$/) do
  step %(que o estudante acessa a página de "Histórico de Refeições")
  Refeicao.where(estudante: @estudante).delete_all
  visit historico_refeicoes_path
end

Então(/^o sistema deve bloquar a geração do arquivo$/) do
  expect(page.response_headers['Content-Type']).not_to include('application/pdf')
end
