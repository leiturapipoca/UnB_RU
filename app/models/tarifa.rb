class Tarifa < ApplicationRecord
  self.table_name = "tarifas"
  belongs_to :grupo_tarifario
  enum :tipo_refeicao, { cafe_da_manha: "CAFE_DA_MANHA", almoco: "ALMOCO", jantar: "JANTAR" }, prefix: :tipo
  validates :valor, numericality: { greater_than_or_equal_to: 0 }
  validates :tipo_refeicao, uniqueness: { scope: :grupo_tarifario_id }
end
