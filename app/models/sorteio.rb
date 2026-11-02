class Sorteio < ApplicationRecord
  self.table_name = "sorteios"
  belongs_to :turno
  has_many :inscricoes_fastpass, dependent: :restrict_with_error
  enum :status, { inscricoes_abertas: "INSCRICOES_ABERTAS", realizado: "REALIZADO", cancelado: "CANCELADO" }, prefix: :status
  validates :data, uniqueness: { scope: :turno_id }, presence: true
  validates :data_hora_resultado, presence: true
end
