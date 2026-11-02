class Estudante < ApplicationRecord
  self.table_name = "estudantes"
  belongs_to :grupo_tarifario
  has_many :recargas, dependent: :restrict_with_error
  has_many :inscricoes_fastpass, dependent: :restrict_with_error
  has_many :acessos, dependent: :restrict_with_error
  validates :matricula, presence: true, uniqueness: true, format: { with: /\A[0-9]{9}\z/ }
  validates :nome, presence: true, length: { maximum: 120 }
  validates :senha_hash, presence: true, length: { maximum: 255 }
  validates :saldo, numericality: true
  validates :notificacoes_ativas, inclusion: { in: [true, false] }
end
