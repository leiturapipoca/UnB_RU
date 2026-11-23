# frozen_string_literal: true

Dado(/^que o administrador está logado(?: no sistema)?$/) do
  # O relatório global exige funcionário logado com perfil de administrador
  administrador = Funcionario.find_or_create_by!(siape: '1000099') do |f|
    f.nome = 'Administrador Teste'
    f.senha_hash = 'hash'
    f.perfil = :administrador
    f.ativo = true
  end
  visit test_login_funcionario_path(administrador.id)
  visit relatorio_global_acessos_path
end

Dado(/^acessa a página de "([^"]*)"$/) do |_pagina|
  visit relatorio_global_acessos_path
end

Dado(/^existem registros de acesso no restaurante "([^"]*)"$/) do |numero_restaurante|
  campus = Campus.find_or_create_by!(nome: 'Campus Darcy Ribeiro')
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I') { |g| g.descricao = 'Isento' }

  turno = Turno.find_or_create_by!(campus: campus, tipo_refeicao: 'ALMOCO') do |t|
    t.hora_inicio = '11:00'
    t.hora_fim = '14:00'
  end

  Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: 'ALMOCO') do |tf|
    tf.valor = 0.0
  end

  restaurante = Restaurante.find_or_create_by!(campus: campus, nome: "Restaurante #{numero_restaurante}") do |r|
    r.piso = 1
  end

  catraca1 = Catraca.find_or_create_by!(restaurante: restaurante, numero: 1) { |c| c.descricao = 'Catraca 1' }
  catraca1.update!(descricao: 'Catraca 1') if catraca1.descricao.blank?

  catraca2 = Catraca.find_or_create_by!(restaurante: restaurante, numero: 2) { |c| c.descricao = 'Catraca 2' }
  catraca2.update!(descricao: 'Catraca 2') if catraca2.descricao.blank?

  func1 = Funcionario.find_or_create_by!(siape: '1000001') do |f|
    f.nome = 'Operador 1'
    f.senha_hash = 'hash'
    f.perfil = :operador
    f.ativo = true
  end

  func2 = Funcionario.find_or_create_by!(siape: '1000002') do |f|
    f.nome = 'Operador 2'
    f.senha_hash = 'hash'
    f.perfil = :operador
    f.ativo = true
  end

  sessao1 = SessaoOperacao.find_by(catraca: catraca1, encerrada_em: nil) ||
            SessaoOperacao.create!(catraca: catraca1, funcionario: func1, iniciada_em: Time.current)

  sessao2 = SessaoOperacao.find_by(catraca: catraca2, encerrada_em: nil) ||
            SessaoOperacao.create!(catraca: catraca2, funcionario: func2, iniciada_em: Time.current)

  @estudante_c1 = Estudante.find_or_create_by!(matricula: '211000111') do |e|
    e.nome = 'Mariana Souza'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end

  @estudante_c2 = Estudante.find_or_create_by!(matricula: '211000222') do |e|
    e.nome = 'Carlos Pereira'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end

  Acesso.create!(
    sessao_operacao: sessao1,
    turno: turno,
    estudante: @estudante_c1,
    identificacao_lida: @estudante_c1.matricula,
    data_hora: Time.current,
    modalidade: :comum,
    resultado: :liberado,
    valor_cobrado: 0.0
  )

  Acesso.create!(
    sessao_operacao: sessao2,
    turno: turno,
    estudante: @estudante_c2,
    identificacao_lida: @estudante_c2.matricula,
    data_hora: Time.current,
    modalidade: :comum,
    resultado: :liberado,
    valor_cobrado: 0.0
  )
  visit relatorio_global_acessos_path
end

Quando(/^o administrador seleciona o filtro de restaurante para "([^"]*)"$/) do |numero_restaurante|
  select "Restaurante #{numero_restaurante}", from: 'Restaurante'
end

Quando(/^seleciona o filtro de catraca para "([^"]*)"$/) do |catraca_desc|
  select catraca_desc, from: 'Catraca'
  click_button 'Filtrar'
end

Então(/^o resultado deve exibir apenas os estudantes que passaram pela "([^"]*)" do restaurante "([^"]*)"$/) do |_catraca, _restaurante|
  expect(page).to have_content(@estudante_c1.nome)
  expect(page).not_to have_content(@estudante_c2.nome)
end

Dado(/^a "([^"]*)" do restaurante "([^"]*)" não teve acessos$/) do |catraca_desc, numero_restaurante|
  campus = Campus.find_or_create_by!(nome: 'Campus Darcy Ribeiro')

  restaurante = Restaurante.find_or_create_by!(campus: campus, nome: "Restaurante #{numero_restaurante}") do |r|
    r.piso = 1
  end

  catraca = Catraca.find_or_create_by!(restaurante: restaurante, numero: 1) do |c|
    c.descricao = catraca_desc
  end
  catraca.update!(descricao: catraca_desc) if catraca.descricao.blank?
  visit relatorio_global_acessos_path
end

Quando(/^o administrador seleciona o restaurante "([^"]*)"$/) do |numero_restaurante|
  select "Restaurante #{numero_restaurante}", from: 'Restaurante'
end

Quando(/^filtra pela "([^"]*)"$/) do |catraca_desc|
  select catraca_desc, from: 'Catraca'
  click_button 'Filtrar'
end

Então(/^a tabela de resultados deve aparecer vazia$/) do
  expect(page).to have_no_css('table tbody tr')
end
