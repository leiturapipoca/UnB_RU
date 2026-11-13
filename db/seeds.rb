# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
require 'json'

puts "Limpando registros antigos..."
ItemCardapio.delete_all
Cardapio.delete_all
Turno.delete_all
Restaurante.delete_all
Campus.delete_all

puts "Criando Campus..."
campus = Campus.create!(nome: 'Darcy Ribeiro')

puts "Criando Turnos..."
turnos = {
  'cafe_da_manha' => Turno.create!(campus: campus, tipo_refeicao: 'CAFE_DA_MANHA', hora_inicio: '07:00:00', hora_fim: '09:00:00'),
  'almoco'        => Turno.create!(campus: campus, tipo_refeicao: 'ALMOCO', hora_inicio: '11:00:00', hora_fim: '14:30:00'),
  'jantar'        => Turno.create!(campus: campus, tipo_refeicao: 'JANTAR', hora_inicio: '17:00:00', hora_fim: '19:30:00')
}


MAPEAMENTO_ITENS = {
  "bebidas"                             => [:bebida, :geral],
  "bebida"                              => [:bebida, :geral],
  "panificacao"                         => [:panificacao, :geral],
  "opcao_extra"                         => [:opcao_extra, :geral],
  "gordura"                             => [:gordura, :geral],
  "complemento_padrao"                  => [:complemento, :padrao],
  "complemento_ovolactovegetariano"     => [:complemento, :ovolactovegetariano],
  "complemento_vegetariano_estrito"     => [:complemento, :vegetariano_estrito],
  "fruta"                               => [:fruta, :geral],
  "salada_1"                            => [:salada, :geral],
  "salada_2"                            => [:salada, :geral],
  "molho_para_salada"                   => [:molho_salada, :geral],
  "prato_principal_padrao"              => [:prato_principal, :padrao],
  "prato_principal_ovolactovegetariano" => [:prato_principal, :ovolactovegetariano],
  "prato_principal_vegetariano_estrito" => [:prato_principal, :vegetariano_estrito],
  "guarnicao"                           => [:guarnicao, :geral],
  "acompanhamentos"                     => [:acompanhamento, :geral],
  "sobremesa"                           => [:sobremesa, :geral],
  "sopa"                                => [:sopa, :geral],
  "torrada"                             => [:torrada, :geral]
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


      valores = valor_json.is_a?(Array) ? valor_json : [valor_json]

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
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
