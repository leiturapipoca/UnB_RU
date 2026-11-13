# Steps da feature features/configuracaoDePontoDeAcesso.feature

Dado(/^que o funcionário acessa a tela de seleção de restaurante$/) do
  @funcionario = criar_funcionario
  @restaurante = criar_restaurante_com_catraca(nome: "RU Darcy")
  @indisponivel = criar_restaurante_com_catraca(nome: "RU Fechado")
  @indisponivel.update!(status: :indisponivel)
  entrar_como(@funcionario)
  visit ponto_acesso_path
end

Dado(/^que o funcionário visualiza a lista de restaurantes disponíveis$/) do
  expect(page).to have_content("RU Darcy")
end

Quando(/^o funcionário seleciona um restaurante da lista$/) do
  choose "catraca_#{@restaurante.catracas.first.id}"
  click_button "Selecionar"
end

Quando(/^o funcionário tenta selecionar um restaurante que não está disponível$/) do
  choose "catraca_#{@indisponivel.catracas.first.id}"
  click_button "Selecionar"
end

Então(/^o sistema direciona as regras corretamente para o restaurante selecionado$/) do
  expect(page).to have_current_path(root_path)
  expect(page).to have_content("Ponto de acesso: RU Darcy")
end

E(/^grava os logs corretamente para o restaurante selecionado$/) do
  sessao = SessaoOperacao.find_by!(funcionario: @funcionario, encerrada_em: nil)
  expect(sessao.catraca.restaurante).to eq(@restaurante)
end

Então(/^o sistema exibe uma mensagem de erro informando que o restaurante não está disponível$/) do
  expect(page).to have_content("não está disponível")
end

E(/^não direciona as regras para o restaurante selecionado$/) do
  expect(page).to have_current_path(ponto_acesso_path)
  expect(page).to have_no_content("Painel de Controle")
end

E(/^não grava os logs para o restaurante selecionado$/) do
  expect(SessaoOperacao.where(funcionario: @funcionario)).to be_empty
end
