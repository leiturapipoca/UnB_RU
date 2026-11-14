# frozen_string_literal: true

# features/step_definitions/recarga_saldo_steps.rb

Dado(/^que o estudante possui "([^"]*)" reais de saldo na conta$/) do |valor|
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo III', descricao: 'Pagante')
  @estudante = Estudante.find_or_create_by!(matricula: '242001508') do |e|
    e.nome = 'Guilherme Silva Cavalcante'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end
  @estudante.update!(saldo: valor.to_f)

  # visit login_path
  # fill_in 'Matrícula', with: @estudante.matricula
  # fill_in 'Senha', with: 'senha_segura_123'
  # click_button 'Entrar'
  visit test_login_path(@estudante.id)
  visit new_recarga_path
end

Quando(/^o estudante selecionar pagamento via "([^"]*)"$/) do |metodo_pagamento|
  choose metodo_pagamento
end

Quando(/^selecionar "([^"]*)" reais$/) do |valor|
  fill_in 'Valor', with: valor
  click_button 'Gerar Cobrança'
end

Quando(/^o pagamento for recebido$/) do
  click_button 'Confirmar Pagamento'
end

Então(/^o saldo da conta deve mudar para "([^"]*)" reais$/) do |saldo_esperado|
  @estudante.reload
  expect(@estudante.saldo.to_f).to eq(saldo_esperado.to_f)
  expect(page).to have_content(saldo_esperado)
end

Quando(/^o pagamento não for efetivado dentro do prazo$/) do
  if page.has_field?('Valor', wait: false) && find_field('Valor').value.blank?
    fill_in 'Valor', with: '50'
    click_button 'Gerar Cobrança'
  end
  click_button 'Simular Expiração'
end

Então(/^o saldo da conta deve permanecer "([^"]*)" reais$/) do |saldo_esperado|
  @estudante.reload
  expect(@estudante.saldo.to_f).to eq(saldo_esperado.to_f)
end

Então(/^uma mensagem deve informar "([^"]*)"$/) do |mensagem|
  expect(page).to have_content(mensagem)
end
