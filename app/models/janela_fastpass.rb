class JanelaFastpass < ApplicationRecord
  self.table_name = "janelas_fastpass"
  belongs_to :turno
  has_many :inscricoes_fastpass, dependent: :restrict_with_error
  validates :hora_inicio, uniqueness: { scope: :turno_id }, presence: true
  validates :hora_fim, presence: true
  validates :cota_vagas, numericality: { greater_than_or_equal_to: 0 }
  validates :ativa, inclusion: { in: [true, false] }
  validate :hora_inicio_menor_que_hora_fim

  private
  def hora_inicio_menor_que_hora_fim
    if hora_inicio.present? && hora_fim.present? && hora_inicio >= hora_fim
      errors.add(:hora_inicio, "deve ser anterior à hora fim")
    end
  end
end
