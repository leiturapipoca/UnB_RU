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
  validates :notificacoes_ativas, inclusion: { in: [ true, false ] }

  def senha_confere?(texto)
    BCrypt::Password.new(senha_hash) == texto
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def self.autenticar(matricula, senha)
    estudante = find_by(matricula: matricula.to_s.strip)
    estudante if estudante&.senha_confere?(senha.to_s)
  end
end
