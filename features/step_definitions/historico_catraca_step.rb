# frozen_string_literal: true

Dado('que a catraca está sem conexão de rede') do
  # Simular modo offline no Capybara pode ser feito injetando um script JS ou mockando a resposta
  page.execute_script("window.navigator.onLine = false;") if page.driver.browser.respond_to?(:execute_script)
  # Ou simular falha no endpoint
  allow_any_instance_of(CatracasController).to receive(:check_connection).and_return(false)
end

Dado('que a catraca possui registros salvos localmente') do
  # Simula registros no LocalStorage (se for PWA) ou na base local
  page.execute_script("localStorage.setItem('acessos_pendentes', '[{\"matricula\":\"123456789\"}]');")
end

Dado('a identificação não pode ser verificada localmente') do
  # Simula que o banco local (IndexedDB) não tem os dados desse aluno
  page.execute_script("window.dados_locais_completos = false;")
end

Quando('um acesso válido é realizado') do
  visit '/catraca/validacao'
  fill_in 'Identificação', with: '123456789'
  click_button 'Validar'
end

Quando('a conexão de rede é reestabelecida') do
  page.execute_script("window.navigator.onLine = true; window.dispatchEvent(new Event('online'));")
end

Quando('a leitura é realizada') do
  step 'um acesso válido é realizado'
end

Então('deve salvar o evento no histórico local') do
  # Checa se o LocalStorage/IndexedDB foi alimentado
  registros = page.evaluate_script("localStorage.getItem('acessos_pendentes');")
  expect(registros).to include('123456789')
end

Então('o sistema deve enviar o histórico local para o servidor central') do
  # Aguarda o request mockado ou checa se o BD principal foi atualizado
  sleep 1 # Dar tempo para o JS fazer o fetch
  expect(Acesso.count).to be > 0
end

Então('deve limpar os registros pendentes da memória local') do
  registros = page.evaluate_script("localStorage.getItem('acessos_pendentes');")
  expect(registros).to be_nil.or eq("[]")
end