class InscricaoFastpass < ApplicationRecord
  self.table_name = "inscricoes_fastpass"
  belongs_to :sorteio
  belongs_to :estudante
  belongs_to :janela_fastpass
  has_many :acessos, dependent: :restrict_with_error
  enum :status, {
    aguardando_sorteio: "AGUARDANDO_SORTEIO", contemplado: "CONTEMPLADO",
    nao_contemplado: "NAO_CONTEMPLADO", vaga_liberada: "VAGA_LIBERADA",
    utilizada: "UTILIZADA", expirada: "EXPIRADA"
  }, prefix: :status
  validates :estudante_id, uniqueness: { scope: :sorteio_id }
  validates :codigo_passe, uniqueness: true, allow_nil: true, length: { maximum: 20 }
  validates :inscrito_em, presence: true
  validate :validade_codigo_passe

  private
  def validade_codigo_passe
    status_validos = %w[contemplado vaga_liberada utilizada expirada]
    if codigo_passe.present? && !status_validos.include?(status)
      errors.add(:codigo_passe, "só pode existir para os status de contemplação/uso")
    end
  end
end
