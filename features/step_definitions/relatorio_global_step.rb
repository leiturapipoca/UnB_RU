# frozen_string_literal: true

# features/step_definitions/relatorio_global_steps.rb

Dado(/^que o administrador está logado(?: no sistema)?$/) do
  @admin = Administrador.find_or_create_by!(email: 'admin@unb.br') do |a|
    a.nome = 'Administrador RU'
    a.senha_hash = 'hash'
  end

  visit admin_login_path
  fill_in 'E-mail', with: @admin.email
  fill_in 'Senha', with: 'admin_seguro_123'
  click_button 'Entrar'
end

Dado(/^acessa a página de "([^"]*)"$/) do |_pagina|
  visit relatorio_global_acessos_path
end

Dado(/^existem registros de acesso no restaurante "([^"]*)"$/) do |numero_restaurante|
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I', descricao: 'Isento')
  restaurante = Restaurante.find_or_create_by!(numero: numero_restaurante)
  catraca1 = Catraca.find_or_create_by!(nome: 'Catraca 1', restaurante: restaurante)
  catraca2 = Catraca.find_or_create_by!(nome: 'Catraca 2', restaurante: restaurante)

  @estudante_c1 = Estudante.create!(
    matricula: '211000111',
    nome: 'Mariana Souza',
    senha_hash: 'hash',
    grupo_tarifario: grupo
  )
  @estudante_c2 = Estudante.create!(
    matricula: '211000222',
    nome: 'Carlos Pereira',
    senha_hash: 'hash',
    grupo_tarifario: grupo
  )

  Acesso.create!(estudante: @estudante_c1, catraca: catraca1, data_hora: Time.current)
  Acesso.create!(estudante: @estudante_c2, catraca: catraca2, data_hora: Time.current)
end

Quando(/^o administrador seleciona o filtro de restaurante para "([^"]*)"$/) do |restaurante|
  select restaurante, from: 'Restaurante'
end

Quando(/^seleciona o filtro de catraca para "([^"]*)"$/) do |catraca|
  select catraca, from: 'Catraca'
  click_button 'Filtrar'
end

Então(/^o resultado deve exibir apenas os estudantes que passaram pela "([^"]*)" do restaurante "([^"]*)"$/) do |_catraca, _restaurante|
  expect(page).to have_content(@estudante_c1.nome)
  expect(page).not_to have_content(@estudante_c2.nome)
end

Dado(/^a "([^"]*)" do restaurante "([^"]*)" não teve acessos$/) do |catraca_nome, numero_restaurante|
  restaurante = Restaurante.find_or_create_by!(numero: numero_restaurante)
  catraca = Catraca.find_or_create_by!(nome: catraca_nome, restaurante: restaurante)
  Acesso.where(catraca: catraca).delete_all
end

Quando(/^o administrador seleciona o restaurante "([^"]*)"$/) do |restaurante|
  select restaurante, from: 'Restaurante'
end

Quando(/^filtra pela "([^"]*)"$/) do |catraca|
  select catraca, from: 'Catraca'
  click_button 'Filtrar'
end

Então(/^a tabela de resultados deve aparecer vazia$/) do
  expect(page).to have_no_css('table tbody tr')
end
