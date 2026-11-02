# frozen_string_literal: true

# Busca os registros base ou cria se não existirem
c = Campus.first || Campus.create!(nome: 'Darcy Ribeiro')
g = GrupoTarifario.first || GrupoTarifario.create!(nome: 'Grupo I', descricao: 'Isento')
r = Restaurante.find_or_create_by!(campus: c, nome: 'Refeitório 1', piso: 1, capacidade_lugares: 300)

# Cria o estudante (que aciona a classe corrigida)
e = Estudante.create!(
  matricula: "242001509",
  nome: "Teste RU 2",
  senha_hash: "hash123",
  grupo_tarifario: g
)

# Cria a recarga que vai disparar a trigger do PostgreSQL
Recarga.create!(
  estudante: e,
  valor: 15.50,
  metodo_pagamento: 'PIX',
  status: 'CONFIRMADA',
  solicitada_em: Time.current,
  confirmada_em: Time.current
)

puts "\n"
puts "========================================"
puts "SUCESSO! O Saldo final do estudante no Banco de Dados eh: R$ #{e.reload.saldo}"
puts "========================================"