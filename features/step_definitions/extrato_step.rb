Dado('que o estudante está logado') do
  @grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I')
  @estudante = Estudante.find_or_create_by!(matricula: '123456789') do |e|
    e.nome = 'João'
    e.senha_hash = 'hash'
    e.grupo_tarifario = @grupo
    e.saldo = 0.0
  end


  visit test_login_path(@estudante.id)
end

Dado('que o estudante não está logado') do
  @grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I')
  @estudante = Estudante.find_or_create_by!(matricula: '987654321') do |e|
    e.nome = 'Maria'
    e.senha_hash = 'hash'
    e.grupo_tarifario = @grupo
    e.saldo = 0.0
  end
end

Dado('ele já fez uma recarga') do
  Recarga.create!(
    estudante: @estudante,
    valor: 50.0,
    metodo_pagamento: 'PIX',
    status: 'CONFIRMADA',
    solicitada_em: Time.current,
    confirmada_em: Time.current
  )
end

Dado('não possui recargas') do
end

Dado('não possui consumos') do
end

Quando('ele tenta acessar a página {string}') do |pagina|
  visit extrato_estudante_path(@estudante)
end

Quando('ele acessa a página {string}') do |pagina|
  visit extrato_estudante_path(@estudante)
end

Então('ele deve ver o valor gasto no mês') do
  expect(page).to have_content('Total Gasto')
end

Então('ele deve ver o valor recarregado') do
  expect(page).to have_content('Total Recarregado')
end

Então('ele deve ver a quantidade de refeições realizadas') do
  expect(page).to have_content('Quantidade de Refeições')
end

Então('ele deve ver o total gasto') do
  expect(page).to have_content('Total Gasto')
end

Então('ele deve ver a mensagem {string}') do |mensagem|
  expect(page).to have_content(mensagem)
end



Então('ele deve ser redirecionado para a página de login') do
  expect(current_path).to eq(login_path)
end
