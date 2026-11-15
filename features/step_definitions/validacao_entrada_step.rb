# frozen_string_literal: true

# Método auxiliar para não repetir código
def setup_infraestrutura_ru
  campus = Campus.find_or_create_by!(nome: 'Darcy Ribeiro')
  rest = Restaurante.find_or_create_by!(campus: campus, nome: 'RU Central', piso: 1, capacidade_lugares: 500)
  catraca = Catraca.find_or_create_by!(restaurante: rest, numero: 1, modo_operacional: 'COMUM', status: 'ONLINE')
  func = Funcionario.find_or_create_by!(siape: '1234567', nome: 'Operador', senha_hash: '123', perfil: 'OPERADOR')

  agora = Time.current
  Turno.find_or_create_by!(campus: campus, tipo_refeicao: 'ALMOCO') do |t|
    t.hora_inicio = (agora - 1.hour).strftime("%H:%M:%S")
    t.hora_fim = (agora + 1.hour).strftime("%H:%M:%S")
  end

  # CORREÇÃO 1: Preenchendo o 'iniciada_em' para passar na validação do Rails
  SessaoOperacao.find_or_create_by!(funcionario: func, catraca: catraca, encerrada_em: nil) do |s|
    s.iniciada_em = Time.current
  end
end

Dado('que o cliente está com a identificação válida') do
  setup_infraestrutura_ru

  @grupo = GrupoTarifario.find_or_create_by!(nome: 'Estudantes')
  Tarifa.find_or_create_by!(grupo_tarifario: @grupo, tipo_refeicao: 'ALMOCO', valor: 2.50)

  @estudante = Estudante.find_or_create_by!(matricula: '123456789') do |e|
    e.nome = 'Estudante Válido'
    e.senha_hash = 'hash'
    e.grupo_tarifario = @grupo
    e.saldo = 50.0
  end
end

Dado('que o cliente possui uma identificação inválida ou sem saldo') do
  setup_infraestrutura_ru # CORREÇÃO 2: Configurando o RU para esse cenário também

  @grupo = GrupoTarifario.find_or_create_by!(nome: 'Estudantes')
  Tarifa.find_or_create_by!(grupo_tarifario: @grupo, tipo_refeicao: 'ALMOCO', valor: 2.50)

  @estudante_sem_saldo = Estudante.find_or_create_by!(matricula: '999999999') do |e|
    e.nome = 'Estudante Sem Saldo'
    e.senha_hash = 'hash'
    e.grupo_tarifario = @grupo
    e.saldo = 0.0 # Sem saldo
  end
end

Dado('que o cliente já validou sua entrada na refeição atual') do
  step 'que o cliente está com a identificação válida'
  step 'ele passa a identificação na catraca'
  step 'o sistema deve registrar a entrada'
end

Quando('ele passa a identificação na catraca') do
  visit '/catraca/validacao' # Rota hipotética da interface da catraca
  fill_in 'Identificação', with: @estudante.matricula
  click_button 'Validar'
end

Quando('ele tenta passar a identificação na catraca') do
  visit '/catraca/validacao'
  matricula = @estudante_sem_saldo ? @estudante_sem_saldo.matricula : '000000000'
  fill_in 'Identificação', with: matricula
  click_button 'Validar'
end

Quando('ele tenta passar a mesma identificação novamente') do
  visit '/catraca/validacao'
  fill_in 'Identificação', with: @estudante.matricula
  click_button 'Validar'
end

Então('a catraca deve ser liberada') do
  expect(page).to have_content('Catraca Liberada')
end

Então('a catraca deve permanecer bloqueada') do
  expect(page).to have_selector('.status-bloqueada') # Exemplo de classe CSS de bloqueio
end

Então('o sistema deve registrar a entrada') do
  expect(Acesso.where(estudante_id: @estudante.id, resultado: 'LIBERADO').count).to eq(1)
end

Então('deve exibir a mensagem {string}') do |mensagem|
  expect(page).to have_content(mensagem)
end
