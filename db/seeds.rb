# Dados para usar o sistema em DESENVOLVIMENTO.
# Rodar com: ruby bin/rails db:seed
# Pode rodar várias vezes: find_or_create_by! só cria o que ainda não existe
# (os cardápios são refeitos a cada execução a partir do cardapio_2.json).
#
# Logins de teste dos funcionários (senha de todos: senha123):
#   Administrador  SIAPE 1000001  -> pode gerenciar restaurantes e catracas
#   Operador       SIAPE 1000002  -> opera a catraca
#   Gestor         SIAPE 1000003  -> turnos, relatório de operação e relatório global

require 'json'

# --- Estrutura base ---------------------------------------------------------

campus = Campus.find_or_create_by!(nome: "Darcy Ribeiro")

# Tarifa: quanto cada grupo paga por refeição (a validação do FastPass depende disso)
grupo = GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Grupo padrão" }
{ cafe_da_manha: 2.00, almoco: 5.00, jantar: 5.00 }.each do |refeicao, valor|
  Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: refeicao) { |t| t.valor = valor }
end

# Funcionários (a senha é guardada com hash pelo método Funcionario#senha=).
# Só fora de produção: em produção NÃO se criam logins com senha conhecida.
if Rails.env.production?
  puts "Produção: funcionários de teste não foram criados (cadastre-os manualmente)."
else
  [
    { siape: "1000001", nome: "Administrador RU", perfil: :administrador },
    { siape: "1000002", nome: "Operador RU", perfil: :operador },
    { siape: "1000003", nome: "Gestor RU", perfil: :gestor }
  ].each do |dados|
    Funcionario.find_or_create_by!(siape: dados[:siape]) do |f|
      f.nome = dados[:nome]
      f.perfil = dados[:perfil]
      f.senha = "senha123"
    end
  end
end

# Um restaurante com uma catraca para a tela de seleção de ponto de acesso
restaurante = Restaurante.find_or_create_by!(campus: campus, nome: "RU Darcy") do |r|
  r.piso = 1
  r.capacidade_lugares = 300
end
restaurante.catracas.find_or_create_by!(numero: 1) { |c| c.descricao = "Entrada principal" }

# --- Turnos e cardápios -----------------------------------------------------

puts "Limpando cardápios antigos..."
ItemCardapio.delete_all
Cardapio.delete_all

puts "Criando Turnos..."
# find_or_create_by!: os turnos podem ter sorteios/acessos ligados, então não são apagados
turnos = {
  'cafe_da_manha' => [ 'CAFE_DA_MANHA', '07:00:00', '09:00:00' ],
  'almoco'        => [ 'ALMOCO',        '11:00:00', '14:30:00' ],
  'jantar'        => [ 'JANTAR',        '17:00:00', '19:30:00' ]
}.transform_values do |tipo, inicio, fim|
  Turno.find_or_create_by!(campus: campus, tipo_refeicao: tipo) do |t|
    t.hora_inicio = inicio
    t.hora_fim = fim
  end
end


MAPEAMENTO_ITENS = {
  "bebidas"                             => [ :bebida, :geral ],
  "bebida"                              => [ :bebida, :geral ],
  "panificacao"                         => [ :panificacao, :geral ],
  "opcao_extra"                         => [ :opcao_extra, :geral ],
  "gordura"                             => [ :gordura, :geral ],
  "complemento_padrao"                  => [ :complemento, :padrao ],
  "complemento_ovolactovegetariano"     => [ :complemento, :ovolactovegetariano ],
  "complemento_vegetariano_estrito"     => [ :complemento, :vegetariano_estrito ],
  "fruta"                               => [ :fruta, :geral ],
  "salada_1"                            => [ :salada, :geral ],
  "salada_2"                            => [ :salada, :geral ],
  "molho_para_salada"                   => [ :molho_salada, :geral ],
  "prato_principal_padrao"              => [ :prato_principal, :padrao ],
  "prato_principal_ovolactovegetariano" => [ :prato_principal, :ovolactovegetariano ],
  "prato_principal_vegetariano_estrito" => [ :prato_principal, :vegetariano_estrito ],
  "guarnicao"                           => [ :guarnicao, :geral ],
  "acompanhamentos"                     => [ :acompanhamento, :geral ],
  "sobremesa"                           => [ :sobremesa, :geral ],
  "sopa"                                => [ :sopa, :geral ],
  "torrada"                             => [ :torrada, :geral ]
}.freeze


hoje = Date.current
inicio_da_semana = hoje.beginning_of_week
dias_da_semana = {
  "segunda-feira" => inicio_da_semana,
  "terca-feira"   => inicio_da_semana + 1.day,
  "quarta-feira"  => inicio_da_semana + 2.days,
  "quinta-feira"  => inicio_da_semana + 3.days,
  "sexta-feira"   => inicio_da_semana + 4.days,
  "sabado"        => inicio_da_semana + 5.days,
  "domingo"       => inicio_da_semana + 6.days
}

puts "Carregando arquivo JSON..."

caminho_arquivo = Rails.root.join('cardapio_2.json')
dados_cardapio = JSON.parse(File.read(caminho_arquivo))

puts "Povoando Cardápios e Itens..."
dados_cardapio.each do |dia_nome, refeicoes|
  data_cardapio = dias_da_semana[dia_nome]

  refeicoes.each do |turno_nome, itens|
    turno = turnos[turno_nome]


    cardapio = Cardapio.create!(turno: turno, data: data_cardapio)

    ordem_seq = 1


    itens.each do |chave_json, valor_json|
      next if valor_json.nil?

      mapeamento = MAPEAMENTO_ITENS[chave_json]
      raise "Chave JSON desconhecida: #{chave_json}" unless mapeamento

      categoria, opcao = mapeamento


      valores = valor_json.is_a?(Array) ? valor_json : [ valor_json ]

      valores.each do |descricao|
        ItemCardapio.create!(
          cardapio: cardapio,
          categoria: categoria,
          opcao: opcao,
          descricao: descricao,
          ordem: ordem_seq
        )
        ordem_seq += 1
      end
    end
  end
end

puts "Banco de dados populado com sucesso com #{Cardapio.count} cardápios e #{ItemCardapio.count} itens!"
