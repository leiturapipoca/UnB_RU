# frozen_string_literal: true

Dado('seleciona um período com movimentações') do
  # Cria dados de teste simulando movimentações
  Acesso.create!(sessao_operacao_id: 1, identificacao_lida: '123', data_hora: Time.current, modalidade: 'COMUM', resultado: 'LIBERADO')
  
  visit relatorios_path
  fill_in 'Data Início', with: Date.yesterday.to_s
  fill_in 'Data Fim', with: Date.tomorrow.to_s
end

Dado('seleciona um período sem registros') do
  Acesso.delete_all
  visit relatorios_path
  fill_in 'Data Início', with: Date.yesterday.to_s
  fill_in 'Data Fim', with: Date.tomorrow.to_s
end

Dado('que o usuário logado não é gestor') do
  @operador = Funcionario.find_or_create_by!(siape: '7654321') do |f|
    f.nome = 'Operador Teste'
    f.senha_hash = 'hash'
    f.perfil = 'OPERADOR' # Não é gestor
    f.ativo = true
  end
  visit '/login'
  fill_in 'SIAPE', with: @operador.siape
  fill_in 'Senha', with: 'senha_secreta'
  click_button 'Entrar'
end

Quando('ele tenta acessar a página de relatórios') do
  visit relatorios_path
end

Então('o sistema deve gerar o arquivo PDF do relatório') do
  # Verifica se o Content-Type do response é PDF
  expect(page.response_headers['Content-Type']).to eq('application/pdf')
end

Então('deve iniciar o download do arquivo') do
  # Verifica se tem o cabeçalho de attachment
  expect(page.response_headers['Content-Disposition']).to match(/attachment/)
end

Então('deve ver a mensagem {string}') do |mensagem|
  expect(page).to have_content(mensagem)
end