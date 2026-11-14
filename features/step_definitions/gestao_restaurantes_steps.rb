# Steps da feature features/gestaoDeRestaurantes.feature
# Os textos vêm da .feature; "funcionarios" aparece sem acento lá mesmo.

# --- Cadastrar ---
Dado(/^que o administrador acessa a tela de cadastro de restaurantes$/) do
  Campus.create!(nome: "Darcy Ribeiro")
  entrar_como(criar_funcionario(perfil: :administrador))
  visit new_restaurante_path
end

Dado(/^que o administrador preenche os campos obrigatórios do restaurante$/) do
  select "Darcy Ribeiro", from: "Campus"
  fill_in "Nome", with: "RU Darcy"
  fill_in "Piso", with: "1"
  fill_in "Capacidade de lugares", with: "300"
end

Dado(/^que o administrador preenche os campos obrigatórios da catraca física$/) do
  fill_in "Número da catraca", with: "1"
  fill_in "Descrição da catraca", with: "Entrada principal"
end

Quando(/^o administrador clica no botão "([^"]*)"$/) do |botao|
  click_button botao
end

Então(/^o sistema salva as informações do restaurante e da catraca física$/) do
  restaurante = Restaurante.find_by!(nome: "RU Darcy")
  expect(restaurante.catracas.pluck(:numero)).to eq([ 1 ])
end

E(/^os funcionarios podem selecionar o restaurante e a catraca física na Aplicação de Controle$/) do
  expect(Restaurante.status_em_operacao.where(nome: "RU Darcy")).to exist
end

# --- Editar ---
Dado(/^que o administrador acessa a tela de edição de restaurantes$/) do
  @restaurante = criar_restaurante_com_catraca(nome: "RU Antigo")
  entrar_como(criar_funcionario(perfil: :administrador))
  visit edit_restaurante_path(@restaurante)
end

Dado(/^que o administrador seleciona um restaurante existente$/) do
  expect(page.html).to include(@restaurante.nome)
end

Dado(/^que o administrador altera os campos obrigatórios do restaurante$/) do
  fill_in "Nome", with: "RU Novo"
  fill_in "Piso", with: "2"
end

Dado(/^que o administrador altera os campos obrigatórios da catraca física$/) do
  fill_in "Número da catraca", with: "2"
  fill_in "Descrição da catraca", with: "Catraca nova"
end

Então(/^o sistema atualiza as informações do restaurante e da catraca física$/) do
  @restaurante.reload
  expect(@restaurante.nome).to eq("RU Novo")
  expect(@restaurante.catracas.first.numero).to eq(2)
end

E(/^os funcionarios podem selecionar o restaurante e a catraca física atualizados na Aplicação de Controle$/) do
  expect(Restaurante.status_em_operacao.where(nome: "RU Novo")).to exist
end

# --- Remover ---
Dado(/^que o administrador acessa a tela de remoção de restaurantes$/) do
  @restaurante = criar_restaurante_com_catraca(nome: "RU Antigo")
  entrar_como(criar_funcionario(perfil: :administrador))
  visit restaurantes_path
end

Então(/^o sistema remove as informações do restaurante e da catraca física$/) do
  expect(Restaurante.exists?(@restaurante.id)).to be false
  expect(Catraca.where(restaurante_id: @restaurante.id)).to be_empty
end

E(/^os funcionarios não podem mais selecionar o restaurante e a catraca física removidos na Aplicação de Controle$/) do
  expect(page).to have_no_content("RU Antigo")
end
