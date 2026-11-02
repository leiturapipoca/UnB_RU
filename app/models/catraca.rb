class Catraca < ApplicationRecord
  self.table_name = "catracas"
  belongs_to :restaurante
  has_many :sessoes_operacao, dependent: :restrict_with_error
  enum :modo_operacional, { comum: "COMUM", exclusivo_fastpass: "EXCLUSIVO_FASTPASS" }, prefix: :modo
  enum :status, { online: "ONLINE", offline: "OFFLINE", pronta: "PRONTA", manutencao: "MANUTENCAO", desativada: "DESATIVADA" }, prefix: :status
  validates :numero, numericality: { greater_than: 0 }, uniqueness: { scope: :restaurante_id }
  validates :descricao, length: { maximum: 80 }, allow_nil: true
end
