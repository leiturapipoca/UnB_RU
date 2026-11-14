Dado(/^que o funcionário acessa a tela de login$/) do
  visit login_path
end

Dado(/^que o funcionário insere credenciais válidas$/) do
  criar_funcionario(siape: "1234567", senha: "senha123")
  fill_in "SIAPE", with: "1234567"
  fill_in "Senha", with: "senha123"
end

Dado(/^que o funcionário insere credenciais inválidas$/) do
  fill_in "SIAPE", with: "9999999"
  fill_in "Senha", with: "errada"
end

Quando(/^o funcionário clica no botão "([^"]*)"$/) do |botao|
  click_button botao
end

Então(/^o sistema autentica a sessão do funcionário$/) do
  expect(page).to have_button("Sair")
end

Então(/^o sistema não autentica a sessão do funcionário$/) do
  expect(page).to have_no_button("Sair")
  expect(page).to have_current_path(login_path)
end

E(/^exibe a tela principal da aplicação de controle para o funcionário operar o sistema de forma segura$/) do
  expect(page).to have_content("Aplicação de Controle")
end

E(/^exibe uma mensagem de erro para o funcionário$/) do
  expect(page).to have_content("SIAPE ou senha inválidos")
end
