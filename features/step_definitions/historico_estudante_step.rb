# frozen_string_literal: true

Dado(/^que o estudante acessa a página de "([^"]*)"$/) do |_pagina|
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I') { |g| g.descricao = 'Isento' }
  @estudante = Estudante.find_or_create_by!(matricula: '242001508') do |e|
    e.nome = 'Guilherme Silva Cavalcante'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end

  visit test_login_path(@estudante.id)
  visit historico_refeicoes_path
end

Dado(/^possui registros de refeições no mês atual$/) do
  campus = Campus.find_or_create_by!(nome: 'Campus Darcy Ribeiro')
  grupo = @estudante.grupo_tarifario

  turno = Turno.find_or_create_by!(campus: campus, tipo_refeicao: 'ALMOCO') do |t|
    t.hora_inicio = '11:00'
    t.hora_fim = '14:00'
  end

  Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: 'ALMOCO') do |tf|
    tf.valor = 0.0
  end

  restaurante = Restaurante.find_or_create_by!(campus: campus, nome: 'Restaurante 1') do |r|
    r.piso = 1
  end

  catraca = Catraca.find_or_create_by!(restaurante: restaurante, numero: 1) do |c|
    c.descricao = 'Catraca 1'
  end

  funcionario = Funcionario.find_or_create_by!(siape: '1000001') do |f|
    f.nome = 'Operador 1'
    f.senha_hash = 'hash'
    f.perfil = :operador
    f.ativo = true
  end

  SessaoOperacao.where(funcionario: funcionario, encerrada_em: nil).update_all(encerrada_em: Time.current)
  SessaoOperacao.where(catraca: catraca, encerrada_em: nil).update_all(encerrada_em: Time.current)
  sessao = SessaoOperacao.create!(catraca: catraca, funcionario: funcionario, iniciada_em: Time.current)

  Acesso.create!(
    sessao_operacao: sessao,
    turno: turno,
    estudante: @estudante,
    identificacao_lida: @estudante.matricula.strip,
    data_hora: Time.current,
    modalidade: :comum,
    resultado: :liberado,
    valor_cobrado: 0.0
  )

  visit historico_refeicoes_path
end

Dado(/^possui apenas recargas confirmadas sem nenhuma refeição registrada$/) do
  Acesso.where(estudante: @estudante).delete_all
  Recarga.where(estudante: @estudante).delete_all
  @estudante.update!(saldo: 0.0)

  Recarga.create!(
    estudante: @estudante,
    valor: 30.0,
    metodo_pagamento: :pix,
    status: :confirmada,
    solicitada_em: 10.minutes.ago,
    confirmada_em: Time.current,
    codigo_transacao: "TRX-BDD-#{SecureRandom.hex(4)}"
  )

  visit historico_refeicoes_path
end

Então(/^ele deve visualizar as recargas no extrato$/) do
  expect(page).to have_content('RECARGA')
  expect(page).to have_content('Total Recarregado')
  expect(page).not_to have_content('Nenhuma movimentação encontrada')
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
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I') { |g| g.descricao = 'Isento' }
  @estudante = Estudante.find_or_create_by!(matricula: '242009999') do |e|
    e.nome = 'Estudante Sem Refeicoes'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end

  Acesso.where(estudante: @estudante).delete_all
  Recarga.where(estudante: @estudante).delete_all
  @estudante.update!(saldo: 0.0)

  visit test_login_path(@estudante.id)
  visit historico_refeicoes_path
end

Então(/^o sistema deve bloquar a geração do arquivo$/) do
  expect(page.response_headers['Content-Type']).not_to include('application/pdf')
end
