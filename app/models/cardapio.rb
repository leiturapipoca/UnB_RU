class Cardapio < ApplicationRecord
  self.table_name = "cardapios"
  belongs_to :turno
  has_many :itens_cardapio, dependent: :destroy
  validates :data, uniqueness: { scope: :turno_id }, presence: true
end
