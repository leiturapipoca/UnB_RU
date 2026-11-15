# frozen_string_literal: true
# features/step_definitions/cadastro_usuario_steps.rb

Dado(/^que o estudante está na tela de "Cadastro"$/) do

  GrupoTarifario.find_or_create_by!(nome: 'Grupo Padrão', descricao: 'Grupo para testes')

  visit new_estudante_path
end

Dado(/^que o estudante forneceu sua matrícula, seu nome e sua senha$/) do

  fill_in 'Matrícula', with: '242001508'
  fill_in 'Nome', with: 'Guilherme Silva Cavalcante'
  fill_in 'Senha', with: 'senha_segura_123'
end

Dado(/^que o estudante não preencheu nenhum campo$/) do
  fill_in 'Matrícula', with: ''
  fill_in 'Nome', with: ''
  fill_in 'Senha', with: ''
end

Dado(/^que o estudante forneceu uma matrícula inválida$/) do
  fill_in 'Matrícula', with: '123'
  fill_in 'Nome', with: 'João da Silva'
  fill_in 'Senha', with: 'senha_segura_123'
end

Dado(/^que o estudante forneceu uma matrícula já registrada$/) do
  grupo = GrupoTarifario.first


  Estudante.create!(
    matricula: '123456789',
    nome: 'Aluno Existente',
    senha_hash: 'hash',
    grupo_tarifario: grupo,
    saldo: 0
  )

  fill_in 'Matrícula', with: '123456789'
  fill_in 'Nome', with: 'Novo Aluno'
  fill_in 'Senha', with: 'nova_senha'
end

Quando(/^ele tenta criar o cadastro$/) do
  click_button 'Cadastrar'
end

Então(/^ele vê "([^"]*)"$/) do |mensagem|

  expect(page).to have_content(mensagem)
end

Então(/^ele vê as regras de preenchimento$/) do
  expect(page).to have_content('A matrícula deve conter exatamente 9 dígitos numéricos')
end

E(/^sua conta do RU é criada$/) do
  estudante = Estudante.find_by(matricula: '242001508')

  expect(estudante).not_to be_nil
  expect(estudante.nome).to eq('Guilherme Silva Cavalcante')
end