require 'json'

Quando('o estudante tenta visualizar o cardápio') do

  ItemCardapio.delete_all
  Cardapio.delete_all
  Turno.delete_all
  Campus.delete_all


  agora = Time.current
  campus = Campus.create!(nome: 'Darcy Ribeiro')

  turno = Turno.create!(
    campus_id: campus.id,
    tipo_refeicao: 'ALMOCO',
    hora_inicio: (agora - 1.hour).strftime("%H:%M:%S"),
    hora_fim: (agora + 1.hour).strftime("%H:%M:%S")
  )

  cardapio = Cardapio.create!(turno_id: turno.id, data: agora.to_date)


  caminho = Rails.root.join('cardapio_2.json')
  json_data = JSON.parse(File.read(caminho))


  almoco = json_data["segunda-feira"]["almoco"]


  ItemCardapio.create!(
    cardapio_id: cardapio.id,
    categoria: 'prato_principal',
    opcao: 'padrao',
    descricao: almoco["prato_principal_padrao"],
    ordem: 1
  )

  ItemCardapio.create!(
    cardapio_id: cardapio.id,
    categoria: 'prato_principal',
    opcao: 'ovolactovegetariano',
    descricao: almoco["prato_principal_ovolactovegetariano"],
    ordem: 2
  )

  ItemCardapio.create!(
    cardapio_id: cardapio.id,
    categoria: 'prato_principal',
    opcao: 'vegetariano_estrito',
    descricao: almoco["prato_principal_vegetariano_estrito"],
    ordem: 3
  )

  visit '/cardapio/atual'
end

Quando('o estudante tenta acessar o cardápio') do
  visit '/cardapio/atual'
end

Então('ele visualiza o cardápio da refeição atual') do
  expect(page).to have_content('Cardápio da Refeição Atual')
end

Então('vê a opção padrão, ovolacovegetariana e vegetariana estrito') do
  expect(page).to have_content('Padrao')
  expect(page).to have_content('Ovolactovegetariano')
  expect(page).to have_content('Vegetariano Estrito')
end

Dado('que o RU não está no horário de funcionamento') do

  ItemCardapio.delete_all
  Cardapio.delete_all
  Turno.delete_all
end