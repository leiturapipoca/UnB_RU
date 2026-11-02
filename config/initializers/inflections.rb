# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end
# config/initializers/inflections.rb
#
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'campus', 'campi'
  inflect.irregular 'restaurante', 'restaurantes'
  inflect.irregular 'catraca', 'catracas'
  inflect.irregular 'grupo_tarifario', 'grupos_tarifarios'
  inflect.irregular 'tarifa', 'tarifas'
  inflect.irregular 'estudante', 'estudantes'
  inflect.irregular 'funcionario', 'funcionarios'
  inflect.irregular 'recarga', 'recargas'
  inflect.irregular 'turno', 'turnos'
  inflect.irregular 'janela_fastpass', 'janelas_fastpass'
  inflect.irregular 'cardapio', 'cardapios'
  inflect.irregular 'item_cardapio', 'itens_cardapio'
  inflect.irregular 'sorteio', 'sorteios'
  inflect.irregular 'inscricao_fastpass', 'inscricoes_fastpass'
  inflect.irregular 'sessao_operacao', 'sessoes_operacao'
  inflect.irregular 'acesso', 'acessos'
end
# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end
