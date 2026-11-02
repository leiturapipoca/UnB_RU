class Funcionario < ApplicationRecord
  self.table_name = "funcionarios"
  has_many :sessoes_operacao, dependent: :restrict_with_error
  enum :perfil, { operador: "OPERADOR", gestor: "GESTOR", administrador: "ADMINISTRADOR" }, prefix: :perfil
  validates :siape, presence: true, uniqueness: true, format: { with: /\A[0-9]{7}\z/ }
  validates :nome, presence: true, length: { maximum: 120 }
  validates :senha_hash, presence: true, length: { maximum: 255 }
  validates :ativo, inclusion: { in: [true, false] }
end
