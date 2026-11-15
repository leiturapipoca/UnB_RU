# frozen_string_literal: true

Dado('que o gestor está logado') do
  @gestor = Funcionario.find_or_create_by!(siape: '1111111') do |f|
    f.nome = 'Gestor Chefe'
    f.senha_hash = 'hash'
    f.perfil = 'GESTOR'
    f.ativo = true
  end

  visit test_login_funcionario_path(@gestor.id)
end

Dado('informa horários válidos para o turno') do
  visit new_turno_path
  select 'Almoço', from: 'Tipo de Refeição'
  fill_in 'Hora início', with: '11:00'
  fill_in 'Hora fim', with: '14:30'
end

Dado('informa um horário que coincide com outro turno existente') do
  # Cria um turno existente primeiro
  Turno.create!(campus_id: Campus.first.id, tipo_refeicao: 'ALMOCO', hora_inicio: '11:00', hora_fim: '14:30')
  
  visit new_turno_path
  select 'Jantar', from: 'Tipo de Refeição'
  fill_in 'Hora início', with: '14:00' # Conflito intencional
  fill_in 'Hora fim', with: '15:00'
end

Dado('que a catraca está fora da janela do turno ativo') do
  # Ajusta o horário do sistema ou cria turnos que não cobrem a hora atual
  Turno.delete_all
end

Quando('ele clica em {string}') do |botao|
  click_button(botao)
end

Quando('o cliente tenta validar sua entrada') do
  visit '/catraca/validacao'
  fill_in 'Identificação', with: '123456789'
  click_button 'Validar'
end

Então('o sistema deve salvar o novo horário') do
  expect(Turno.count).to be > 0
end

Então('o sistema não deve salvar o turno') do
  expect(Turno.where(hora_inicio: '14:00').count).to eq(0)
end