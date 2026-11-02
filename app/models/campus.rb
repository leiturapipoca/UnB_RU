class Campus < ApplicationRecord
  self.table_name = "campi"
  has_many :restaurantes, dependent: :restrict_with_error
  has_many :turnos, dependent: :restrict_with_error
  validates :nome, presence: true, uniqueness: true, length: { maximum: 80 }
end
