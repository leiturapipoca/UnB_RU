class Restaurante < ApplicationRecord
  self.table_name = "restaurantes"
  belongs_to :campus
  # Ao remover o restaurante, removemos as catracas dele. Se alguma catraca já tem sessão
  # de operação (histórico), o Rails recusa e o controller mostra uma mensagem.
  has_many :catracas, dependent: :destroy
  # Permite criar/editar as catracas no mesmo formulário do restaurante
  accepts_nested_attributes_for :catracas,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["numero"].blank? && attrs["descricao"].blank? }
  enum :status, { em_operacao: "EM_OPERACAO", indisponivel: "INDISPONIVEL", desativado: "DESATIVADO" }, prefix: :status
  validates :nome, presence: true, length: { maximum: 80 }, uniqueness: { scope: :campus_id }
  validates :piso, numericality: { greater_than_or_equal_to: 1 }
  validates :capacidade_lugares, numericality: { greater_than: 0 }, allow_nil: true
end
