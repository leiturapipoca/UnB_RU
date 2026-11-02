class SessaoOperacao < ApplicationRecord
  self.table_name = "sessoes_operacao"
  belongs_to :funcionario
  belongs_to :catraca
  has_many :acessos, dependent: :restrict_with_error
  validates :iniciada_em, presence: true
  validates :catraca_id, uniqueness: { conditions: -> { where(encerrada_em: nil) }, message: "já possui uma sessão aberta" }
  validates :funcionario_id, uniqueness: { conditions: -> { where(encerrada_em: nil) }, message: "já possui uma sessão aberta" }
  validate :encerrada_em_valida

  private
  def encerrada_em_valida
    if encerrada_em.present? && iniciada_em.present? && encerrada_em <= iniciada_em
      errors.add(:encerrada_em, "deve ser posterior ao início da sessão")
    end
  end
end
