# frozen_string_literal: true

MAPA_TURNOS_FASTPASS = {
  "Café da Manhã" => :cafe_da_manha,
  "Almoço" => :almoco,
  "Jantar" => :jantar
}.freeze

def preparar_cenario_fastpass(turno_nome)
  campus = Campus.find_or_create_by!(nome: "Campus Darcy Ribeiro")
  grupo = GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Isento" }
  tipo_enum = MAPA_TURNOS_FASTPASS.fetch(turno_nome)

  @turno = Turno.find_or_create_by!(campus: campus, tipo_refeicao: tipo_enum) do |t|
    t.hora_inicio = "11:00"
    t.hora_fim = "14:00"
    t.ativo = true
    t.fastpass_habilitado = true
  end
  @turno.update!(fastpass_habilitado: true)

  @janela1 = JanelaFastpass.find_or_create_by!(turno: @turno, hora_inicio: "11:00") do |j|
    j.hora_fim = "11:30"
    j.cota_vagas = 50
    j.ativa = true
  end

  @janela2 = JanelaFastpass.find_or_create_by!(turno: @turno, hora_inicio: "11:30") do |j|
    j.hora_fim = "12:00"
    j.cota_vagas = 50
    j.ativa = true
  end

  @sorteio = Sorteio.find_or_create_by!(turno: @turno, data: Date.current) do |s|
    s.data_hora_resultado = Time.current + 2.hours
    s.status = :inscricoes_abertas
  end
  @sorteio.update!(status: :inscricoes_abertas)

  @estudante = Estudante.find_or_create_by!(matricula: "231000555") do |e|
    e.nome = "Lucas Almeida"
    e.senha_hash = "hash"
    e.grupo_tarifario = grupo
  end
end

Dado(/^que o estudante ainda não possui inscrição para o turno "([^"]*)"$/) do |turno_nome|
  preparar_cenario_fastpass(turno_nome)
  InscricaoFastpass.where(estudante: @estudante).delete_all
  visit test_login_path(@estudante.id)
  visit nova_inscricao_fastpass_path
end

Quando(/^ele seleciona o time-frame "([^"]*)" para "([^"]*)"$/) do |faixa, turno_nome|
  select turno_nome, from: "Turno"
  select faixa, from: "Time-frame"
end

Quando(/^confirma a inscrição$/) do
  click_button "Confirmar Inscrição"
end

Então(/^o status da inscrição deve ser "([^"]*)"$/) do |status_esperado|
  expect(page).to have_content(status_esperado)
end

Dado(/^que o estudante já se inscreveu em um time-frame para o turno "([^"]*)"$/) do |turno_nome|
  preparar_cenario_fastpass(turno_nome)
  InscricaoFastpass.where(estudante: @estudante).delete_all

  InscricaoFastpass.create!(
    sorteio: @sorteio,
    estudante: @estudante,
    janela_fastpass: @janela1,
    inscrito_em: Time.current,
    status: :aguardando_sorteio
  )

  visit test_login_path(@estudante.id)
end

Quando(/^o estudante tentar selecionar um novo time-frame$/) do
  visit nova_inscricao_fastpass_path
end

Então(/^nenhuma opção de time-frame deve estar disponível$/) do
  expect(page).to have_no_select("Time-frame")
  expect(page).to have_no_css("select#inscricao_fastpass_janela_fastpass_id option")
end
