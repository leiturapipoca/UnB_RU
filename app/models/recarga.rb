class Recarga < ApplicationRecord
  self.table_name = "recargas"
  belongs_to :estudante
  enum :metodo_pagamento, { pix: "PIX", cartao_credito: "CARTAO_CREDITO" }, prefix: :metodo
  enum :status, { pendente: "PENDENTE", confirmada: "CONFIRMADA", falhou: "FALHOU", expirada: "EXPIRADA" }, prefix: :status
  validates :valor, numericality: { greater_than: 0 }
  validates :codigo_transacao, uniqueness: true, allow_nil: true, length: { maximum: 64 }
  validates :solicitada_em, presence: true
  validate :consistencia_status_confirmacao

  private
  def consistencia_status_confirmacao
    if (status == "confirmada" && confirmada_em.nil?) || (status != "confirmada" && !confirmada_em.nil?)
      errors.add(:confirmada_em, "deve estar preenchida se, e somente se, o status for CONFIRMADA")
    end
  end
end
