class GrupoTarifario < ApplicationRecord
  self.table_name = "grupos_tarifarios"
  has_many :tarifas, dependent: :destroy
  has_many :estudantes, dependent: :restrict_with_error
  validates :nome, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :descricao, length: { maximum: 200 }, allow_nil: true
end
