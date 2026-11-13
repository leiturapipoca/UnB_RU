class Funcionario < ApplicationRecord
  self.table_name = "funcionarios"
  has_many :sessoes_operacao, dependent: :restrict_with_error
  enum :perfil, { operador: "OPERADOR", gestor: "GESTOR", administrador: "ADMINISTRADOR" }, prefix: :perfil
  validates :siape, presence: true, uniqueness: true, format: { with: /\A[0-9]{7}\z/ }
  validates :nome, presence: true, length: { maximum: 120 }
  validates :senha_hash, presence: true, length: { maximum: 255 }
  validates :ativo, inclusion: { in: [ true, false ] }

  # Atributo virtual: recebe a senha em texto e guarda só o hash em senha_hash
  def senha=(texto)
    self.senha_hash = BCrypt::Password.create(texto) if texto.present?
  end

  def senha_confere?(texto)
    BCrypt::Password.new(senha_hash) == texto
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def self.autenticar(siape, senha)
    funcionario = find_by(siape: siape.to_s.strip, ativo: true)
    funcionario if funcionario&.senha_confere?(senha.to_s)
  end
end
