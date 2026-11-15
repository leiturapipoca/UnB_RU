# frozen_string_literal: true

Dado('que a catraca está sem conexão de rede') do
  page.driver.post(catraca_offline_path)
  visit catraca_validacao_path
end

Dado('que a catraca está offline') do
  step 'que a catraca está sem conexão de rede'
end

Dado('que a catraca possui registros salvos localmente') do
  campus = Campus.find_or_create_by!(nome: 'Darcy Ribeiro')
  rest = Restaurante.find_or_create_by!(campus: campus, nome: 'RU Central', piso: 1, capacidade_lugares: 500)
  catraca = Catraca.find_or_create_by!(restaurante: rest, numero: 1, modo_operacional: 'COMUM', status: 'ONLINE')
  func = Funcionario.find_or_create_by!(siape: '1234567', nome: 'Operador', senha_hash: '123', perfil: 'OPERADOR')

  Turno.find_or_create_by!(campus: campus, tipo_refeicao: 'ALMOCO') do |t|
    t.hora_inicio = (Time.current - 1.hour).strftime('%H:%M:%S')
    t.hora_fim = (Time.current + 1.hour).strftime('%H:%M:%S')
  end

  SessaoOperacao.find_or_create_by!(funcionario: func, catraca: catraca, encerrada_em: nil) do |s|
    s.iniciada_em = Time.current
  end

  grupo = GrupoTarifario.find_or_create_by!(nome: 'Estudantes')
  Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: 'ALMOCO') { |t| t.valor = 2.50 }

  Estudante.find_or_create_by!(matricula: '123456789') do |e|
    e.nome = 'Estudante Teste'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
    e.saldo = 20.0
  end

  step 'que a catraca está sem conexão de rede'
  fill_in 'Identificação', with: '123456789'
  click_button 'Validar'
end

Dado('a identificação não pode ser verificada localmente') do
  @matricula_invalida = ''
end

Quando('um acesso válido é realizado') do
  fill_in 'Identificação', with: '123456789'
  click_button 'Validar'
end

Quando('a leitura é realizada') do
  fill_in 'Identificação', with: @matricula_invalida
  click_button 'Validar'
end

Quando('a conexão de rede é reestabelecida') do
  page.driver.post(catraca_sincronizar_path)
  visit catraca_validacao_path
end

Então('a catraca deve liberar a entrada') do
  expect(page).to have_content('Catraca Liberada')
end

Então('deve salvar o evento no histórico local') do
  expect(Acesso.count).to eq(0)
  expect(page).to have_css('[data-pendentes="1"]')
end

Então('o sistema deve enviar o histórico local para o servidor central') do
  expect(Acesso.where(identificacao_lida: '123456789').where.not(sincronizado_em: nil).count).to eq(1)
end

Então('deve limpar os registros pendentes da memória local') do
  expect(page).to have_css('[data-pendentes="0"]')
end
