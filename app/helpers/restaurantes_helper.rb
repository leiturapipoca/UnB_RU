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

  def rotulo_status_catraca(chave)
    STATUS_CATRACA.fetch(chave.to_s, chave.to_s.humanize)
  end

  # Selos coloridos de status, como nas telas do Figma: <span class="selo selo--verde">Em operação</span>
  def selo_status_restaurante(restaurante)
    cor = if restaurante.status_em_operacao? then "verde"
    elsif restaurante.status_desativado? then "vermelho"
    else "ambar"
    end
    tag.span(rotulo_status_restaurante(restaurante.status), class: "selo selo--#{cor}")
  end

  def selo_status_catraca(catraca)
    cor = { "online" => "verde", "pronta" => "verde", "manutencao" => "ambar", "desativada" => "vermelho" }[catraca.status.to_s]
    tag.span(rotulo_status_catraca(catraca.status), class: [ "selo", ("selo--#{cor}" if cor) ].compact.join(" "))
  end
end
