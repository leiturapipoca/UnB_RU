class Recarga < ApplicationRecord
  self.table_name = "recargas"
  MAX_VALOR = BigDecimal("99999999.99")
  belongs_to :estudante
  enum :metodo_pagamento, { pix: "PIX", cartao_credito: "CARTAO_CREDITO" }, prefix: :metodo
  enum :status, { pendente: "PENDENTE", confirmada: "CONFIRMADA", falhou: "FALHOU", expirada: "EXPIRADA" }, prefix: :status
  validates :metodo_pagamento, presence: { message: "deve ser selecionado" }
  validates :valor, presence: true, numericality: {
    greater_than: 0,
    less_than_or_equal_to: MAX_VALOR,
    message: "deve ser maior que zero e menor que R$ 100.000.000,00"
  }
  validates :codigo_transacao, uniqueness: true, allow_nil: true, length: { maximum: 64 }
  validates :solicitada_em, presence: true
  validate :consistencia_status_confirmacao
  validate :limite_arredondamento_e_saldo
  private

  def consistencia_status_confirmacao
    if (status == "confirmada" && confirmada_em.nil?) || (status != "confirmada" && !confirmada_em.nil?)
      errors.add(:confirmada_em, "deve estar preenchida se, e somente se, o status for CONFIRMADA")
    end
  end

  def limite_arredondamento_e_saldo
    return if valor.blank? || valor <= 0

    valor_arredondado = valor.to_d.round(2)
    if valor_arredondado > MAX_VALOR
      errors.add(:valor, "deve ser menor que R$ 100.000.000,00")
      return
    end

    if estudante.present? && (estudante.saldo.to_d + valor_arredondado).round(2) > MAX_VALOR
      errors.add(:valor, "ultrapassa o limite máximo de saldo permitido (R$ 99.999.999,99)")
    end
  end
end
