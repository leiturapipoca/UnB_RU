# frozen_string_literal: true

Dado('que a catraca está sem conexão de rede') do
  visit catraca_validacao_path
  
  # Usamos o page.execute_script para injetar JavaScript direto no navegador de teste
  # Sobrescrevemos a propriedade navigator.onLine para forçar o sistema a achar que caiu a internet
  page.execute_script("Object.defineProperty(navigator, 'onLine', { value: false, configurable: true });")
end

Dado('que a catraca está offline') do
  step 'que a catraca está sem conexão de rede'
end

Dado('que a catraca possui registros salvos localmente') do
  # 1. Configura a infraestrutura no Banco de Dados para que a sincronização funcione
  campus = Campus.find_or_create_by!(nome: 'Darcy Ribeiro')
  rest = Restaurante.find_or_create_by!(campus: campus, nome: 'RU Central', piso: 1, capacidade_lugares: 500)
  catraca = Catraca.find_or_create_by!(restaurante: rest, numero: 1, modo_operacional: 'COMUM', status: 'ONLINE')
  func = Funcionario.find_or_create_by!(siape: '1234567', nome: 'Operador', senha_hash: '123', perfil: 'OPERADOR')
  
  Turno.find_or_create_by!(campus: campus, tipo_refeicao: 'ALMOCO') do |t|
    t.hora_inicio = (Time.current - 1.hour).strftime("%H:%M:%S")
    t.hora_fim = (Time.current + 1.hour).strftime("%H:%M:%S")
  end

  SessaoOperacao.find_or_create_by!(funcionario: func, catraca: catraca, encerrada_em: nil) do |s|
    s.iniciada_em = Time.current 
  end

  # Cria o aluno
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Estudantes')
  Estudante.find_or_create_by!(matricula: '123456789') do |e|
    e.nome = 'Estudante Teste'
    e.senha_hash = 'hash'
    e.grupo_tarifario = grupo
  end

  # 2. Injeta um acesso pendente direto no LocalStorage do navegador
  visit catraca_validacao_path
  page.execute_script("localStorage.setItem('acessos_offline', JSON.stringify(['123456789']));")
end

Dado('a identificação não pode ser verificada localmente') do
  @matricula_invalida = "" # Nosso JS barra matrículas vazias quando está offline
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
  # Restaura a propriedade para true e dispara o evento 'online' que o nosso Stimulus está escutando
  page.execute_script("Object.defineProperty(navigator, 'onLine', { value: true, configurable: true });")
  page.execute_script("window.dispatchEvent(new Event('online'));")
  
  sleep 1 # Dá 1 segundo para o fetch (AJAX) ir no backend e voltar
end

Então('a catraca deve liberar a entrada') do
  expect(page).to have_content('Catraca Liberada')
end

Então('deve salvar o evento no histórico local') do
  # O evaluate_script roda o JS no navegador e devolve o valor para o Ruby
  acessos_offline = page.evaluate_script("JSON.parse(localStorage.getItem('acessos_offline')) || []")
  expect(acessos_offline).to include('123456789')
end

Então('o sistema deve enviar o histórico local para o servidor central') do
  expect(page).to have_content('Sincronizado com sucesso')
end

Então('deve limpar os registros pendentes da memória local') do
  acessos_offline = page.evaluate_script("localStorage.getItem('acessos_offline')")
  expect(acessos_offline).to be_nil
end
