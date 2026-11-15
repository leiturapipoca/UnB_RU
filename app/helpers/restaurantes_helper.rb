# Rótulos em português (com acento) para os valores guardados nas colunas de status e modo.
# O valor gravado no banco continua sendo a chave (ex.: "em_operacao"); só o texto exibido muda.
module RestaurantesHelper
  STATUS_RESTAURANTE = {
    "em_operacao" => "Em operação",
    "indisponivel" => "Indisponível",
    "desativado" => "Desativado"
  }.freeze

  STATUS_CATRACA = {
    "online" => "Online",
    "offline" => "Offline",
    "pronta" => "Pronta",
    "manutencao" => "Em manutenção",
    "desativada" => "Desativada"
  }.freeze

  MODO_CATRACA = {
    "comum" => "Comum",
    "exclusivo_fastpass" => "Exclusivo FastPass"
  }.freeze

  def rotulo_status_restaurante(chave)
    STATUS_RESTAURANTE.fetch(chave.to_s, chave.to_s.humanize)
  end

  # Lista de [texto, valor] para o f.select
  def opcoes_status_restaurante
    STATUS_RESTAURANTE.map { |chave, rotulo| [ rotulo, chave ] }
  end

  def opcoes_status_catraca
    STATUS_CATRACA.map { |chave, rotulo| [ rotulo, chave ] }
  end

  def opcoes_modo_catraca
    MODO_CATRACA.map { |chave, rotulo| [ rotulo, chave ] }
  end
end
