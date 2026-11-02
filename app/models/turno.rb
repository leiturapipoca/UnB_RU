class Turno < ApplicationRecord
  self.table_name = "turnos"
  belongs_to :campus
  has_many :janelas_fastpass, dependent: :destroy
  has_many :cardapios, dependent: :destroy
  has_many :sorteios, dependent: :destroy
  has_many :acessos, dependent: :restrict_with_error
  enum :tipo_refeicao, { cafe_da_manha: "CAFE_DA_MANHA", almoco: "ALMOCO", jantar: "JANTAR" }, prefix: :tipo
  validates :tipo_refeicao, uniqueness: { scope: :campus_id }
  validates :tolerancia_atraso_min, numericality: { greater_than_or_equal_to: 0 }
  validates :antecedencia_min, numericality: { greater_than_or_equal_to: 0 }
  validates :ativo, :fastpass_habilitado, :trava_pontualidade, inclusion: { in: [true, false] }
  validates :hora_inicio, :hora_fim, presence: true
  validate :hora_inicio_menor_que_hora_fim

  private
  def hora_inicio_menor_que_hora_fim
    if hora_inicio.present? && hora_fim.present? && hora_inicio >= hora_fim
      errors.add(:hora_inicio, "deve ser anterior à hora_fim")
    end
  end
end
