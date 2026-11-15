# frozen_string_literal: true

Dado('seleciona um período com movimentações') do
  campus = Campus.find_or_create_by!(nome: 'Darcy Ribeiro')
  restaurante = Restaurante.find_or_create_by!(campus: campus, nome: 'RU Central', piso: 1, capacidade_lugares: 500)
  catraca = Catraca.find_or_create_by!(restaurante: restaurante, numero: 1, modo_operacional: 'COMUM', status: 'ONLINE')
  operador_catraca = Funcionario.find_or_create_by!(siape: '3333333', nome: 'Operador Catraca', senha_hash: 'hash', perfil: 'OPERADOR')

  turno = Turno.find_or_create_by!(campus: campus, tipo_refeicao: 'ALMOCO') do |t|
    t.hora_inicio = (Time.current - 1.hour).strftime('%H:%M:%S')
    t.hora_fim = (Time.current + 1.hour).strftime('%H:%M:%S')
  end

  sessao = SessaoOperacao.find_by(catraca: catraca, encerrada_em: nil) ||
           SessaoOperacao.create!(funcionario: operador_catraca, catraca: catraca, iniciada_em: Time.current)

  grupo = GrupoTarifario.find_or_create_by!(nome: 'Estudantes')
  Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: 'ALMOCO') { |t| t.valor = 2.50 }

  estudante = Estudante.find_or_create_by!(matricula: '123456789') do |e|
    e.nome = 'Estudante Teste'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
    e.saldo = 50.0
  end

  Acesso.create!(
    sessao_operacao: sessao,
    turno: turno,
    estudante: estudante,
    identificacao_lida: estudante.matricula,
    data_hora: Time.current,
    modalidade: 'COMUM',
    resultado: 'LIBERADO'
  )

  visit relatorios_path
  fill_in 'Data Início', with: Date.yesterday.to_s
  fill_in 'Data Fim', with: Date.tomorrow.to_s
end

Dado('seleciona um período sem registros') do
  ActiveRecord::Base.connection.execute('TRUNCATE TABLE acessos CASCADE')

  visit relatorios_path
  fill_in 'Data Início', with: Date.yesterday.to_s
  fill_in 'Data Fim', with: Date.tomorrow.to_s
end

Dado('que o usuário logado não é gestor') do
  @operador = Funcionario.find_or_create_by!(siape: '7654321') do |f|
    f.nome = 'Operador Teste'
    f.senha_hash = 'hash'
    f.perfil = 'OPERADOR'
    f.ativo = true
  end

  visit test_login_funcionario_path(@operador.id)
end

Quando('ele tenta acessar a página de relatórios') do
  visit relatorios_path
end

Então('o sistema deve gerar o arquivo PDF do relatório') do
  expect(page.response_headers['Content-Type']).to include('application/pdf')
end

Então('deve iniciar o download do arquivo') do
  expect(page.response_headers['Content-Disposition']).to include('attachment')
end

Então('o sistema não deve gerar o PDF') do
  expect(page.response_headers['Content-Type']).not_to include('application/pdf')
end

Então('ele deve ser redirecionado para a página inicial') do
  expect(current_path).to eq(root_path)
end

Então('deve ver a mensagem {string}') do |mensagem|
  expect(page).to have_content(mensagem)
end
