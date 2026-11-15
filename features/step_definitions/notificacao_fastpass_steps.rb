# frozen_string_literal: true

Before do |scenario|
  @status_sorteio = scenario.name.downcase.include?('não ganhou') ? 'NAO_CONTEMPLADO' : 'CONTEMPLADO'
end

Dado('que o usuário está cadastrado') do
  @grupo = GrupoTarifario.first || GrupoTarifario.create!(nome: 'Padrão')
  @estudante = Estudante.create!(
    matricula: '242001508',
    nome: 'Guilherme Silva',
    senha_hash: 'hash123',
    grupo_tarifario: @grupo,
    notificacoes_ativas: true,
    saldo: 0
  )
  ActionMailer::Base.deliveries.clear
end

Dado('que o estudante bloqueou notificações') do
  @estudante.update!(notificacoes_ativas: false)
end

Quando('falta 1 hora para o time frame escolhido pelo estudante') do
  @campus = Campus.first || Campus.create!(nome: 'Campus Darcy Ribeiro')

  @turno = Turno.first || Turno.create!(campus: @campus, tipo_refeicao: 'ALMOCO', hora_inicio: '12:00', hora_fim: '14:30')
  @sorteio = Sorteio.create!(turno: @turno, data: Date.current, data_hora_resultado: Time.current)
  @janela = JanelaFastpass.create!(turno: @turno, hora_inicio: '12:00', hora_fim: '12:15', cota_vagas: 10)

  @inscricao = InscricaoFastpass.create!(
    estudante: @estudante,
    sorteio: @sorteio,
    janela_fastpass: @janela,
    status: @status_sorteio,
    codigo_passe: (@status_sorteio == 'CONTEMPLADO' ? 'PASSE123' : nil),
    inscrito_em: Time.current
  )

  travel_to(@janela.hora_inicio.to_time - 1.hour) do
    NotificadorFastpass.processar(@sorteio)
  end
end

Então('ele recebe uma notificação de resultado do sorteio') do
  expect(ActionMailer::Base.deliveries).not_to be_empty

  @ultimo_email = ActionMailer::Base.deliveries.last
  expect(@ultimo_email.to.first).to include(@estudante.matricula.strip)
end

E('vê {string}') do |mensagem|
  expect(@ultimo_email.subject).to include(mensagem)
end

Então('ele não recebe uma notificação com o resultado do sorteio') do
  expect(ActionMailer::Base.deliveries).to be_empty

  @inscricao.reload
  expect(@inscricao.notificado_em).not_to be_nil
end
