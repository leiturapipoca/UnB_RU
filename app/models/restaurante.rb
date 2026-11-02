class Restaurante < ApplicationRecord
  self.table_name = "restaurantes"
  belongs_to :campus
  has_many :catracas, dependent: :restrict_with_error
  enum :status, { em_operacao: "EM_OPERACAO", indisponivel: "INDISPONIVEL", desativado: "DESATIVADO" }, prefix: :status
  validates :nome, presence: true, length: { maximum: 80 }, uniqueness: { scope: :campus_id }
  validates :piso, numericality: { greater_than_or_equal_to: 1 }
  validates :capacidade_lugares, numericality: { greater_than: 0 }, allow_nil: true
end
