# Dados mínimos para usar o sistema em DESENVOLVIMENTO.
# Rodar com: ruby bin/rails db:seed
# Pode rodar várias vezes: find_or_create_by! só cria o que ainda não existe.
#
# Logins de teste (senha de todos: senha123):
#   Administrador  SIAPE 1000001  -> pode gerenciar restaurantes e catracas
#   Operador       SIAPE 1000002  -> opera a catraca

campus = Campus.find_or_create_by!(nome: "Darcy Ribeiro")

# Tarifa: quanto cada grupo paga por refeição (a validação do FastPass depende disso)
grupo = GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Grupo padrão" }
{ cafe_da_manha: 2.00, almoco: 5.00, jantar: 5.00 }.each do |refeicao, valor|
  Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: refeicao) { |t| t.valor = valor }
end

# Funcionários (a senha é guardada com hash pelo método Funcionario#senha=)
[
  { siape: "1000001", nome: "Administrador RU", perfil: :administrador },
  { siape: "1000002", nome: "Operador RU", perfil: :operador }
].each do |dados|
  Funcionario.find_or_create_by!(siape: dados[:siape]) do |f|
    f.nome = dados[:nome]
    f.perfil = dados[:perfil]
    f.senha = "senha123"
  end
end

# Um restaurante com uma catraca para a tela de seleção de ponto de acesso
restaurante = Restaurante.find_or_create_by!(campus: campus, nome: "RU Darcy") do |r|
  r.piso = 1
  r.capacidade_lugares = 300
end
restaurante.catracas.find_or_create_by!(numero: 1) { |c| c.descricao = "Entrada principal" }
