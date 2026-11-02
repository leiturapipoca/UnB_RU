# frozen_string_literal: true

# features/step_definitions/cadastro_usuario_steps.rb

# --- Contexto ---
Dado(/^que o estudante está na tela de "Cadastro"$/) do
  # O Capybara visita a rota (URI helper) correspondente à página de novo estudante
  visit new_estudante_path
end

# --- Dados do Cenário: Cadastro bem sucedido ---
Dado(/^que o estudante forneceu sua matrícula, seu nome e sua senha$/) do
  # O Capybara preenche os campos do formulário na tela
  fill_in 'Matrícula', with: '242001508'
  fill_in 'Nome', with: 'Guilherme Silva Cavalcante'
  fill_in 'Senha', with: 'senha_segura_123'
end

# --- Dados do Cenário: Tentativa de cadastro com campos vazios ---
Dado(/^que o estudante não preencheu nenhum campo$/) do
  # Deixa os campos em branco explicitamente ou apenas não faz nada,
  # pois ao visitar a página, os campos já estarão vazios.
  fill_in 'Matrícula', with: ''
  fill_in 'Nome', with: ''
  fill_in 'Senha', with: ''
end

# --- Dados do Cenário: Tentativa de cadastro com matrícula inválida ---
Dado(/^que o estudante forneceu uma matrícula inválida$/) do
  # A matricula no banco exige exatamente 9 dígitos.
  fill_in 'Matrícula', with: '123' # Matrícula com tamanho incorreto
  fill_in 'Nome', with: 'João da Silva'
  fill_in 'Senha', with: 'senha_segura_123'
end

# --- Dados do Cenário: Tentativa de cadastro com matrícula já registrada ---
Dado(/^que o estudante forneceu uma matrícula já registrada$/) do
  # Primeiro, garantimos que existe um grupo tarifário para o estudante.
  grupo = GrupoTarifario.find_or_create_by!(nome: 'Grupo I', descricao: 'Isento')

  # Cadastramos o estudante no banco de dados diretamente antes de tentar preencher o form.
  Estudante.create!(matricula: '123456789', nome: 'Aluno Existente', senha_hash: 'hash', grupo_tarifario: grupo)

  # Preenche o formulário com a mesma matrícula para forçar o erro de duplicidade.
  fill_in 'Matrícula', with: '123456789'
  fill_in 'Nome', with: 'Novo Aluno'
  fill_in 'Senha', with: 'nova_senha'
end

# --- Ação (Quando) comum a todos os cenários ---
Quando(/^ele tenta criar o cadastro$/) do
  # O Capybara simula o clique no botão de submissão do formulário
  click_button 'Cadastrar'
end

# --- Verificações (Então / E) ---
Então(/^ele vê "([^"]*)"$/) do |mensagem|
  # Expressão regular captura a mensagem entre aspas e passa como argumento[cite: 368]
  # O Capybara verifica se o texto está presente no HTML renderizado
  expect(page).to have_content(mensagem)
end

Então(/^ele vê as regras de preenchimento$/) do
  # Verifica se a interface exibiu dicas de formatação ao rejeitar a matrícula
  expect(page).to have_content('A matrícula deve conter exatamente 9 dígitos numéricos')
end

E(/^sua conta do RU é criada$/) do
  # Acessa o banco de dados via Active Record para garantir que o registro existe
  estudante = Estudante.find_by(matricula: '242001508')
  expect(estudante).not_to be_nil
  expect(estudante.nome).to eq('Guilherme Silva Cavalcante')
end