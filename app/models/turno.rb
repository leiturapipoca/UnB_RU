# frozen_string_literal: true

class Turno < ApplicationRecord
  TIPO_LABELS = {
    "cafe_da_manha" => "Café da Manhã",
    "almoco" => "Almoço",
    "jantar" => "Jantar"
  }.freeze

  belongs_to :campus
  has_many :acessos
  has_many :janelas_fastpass, class_name: "JanelaFastpass", dependent: :destroy
  has_many :sorteios, dependent: :restrict_with_error

  enum :tipo_refeicao, {
    cafe_da_manha: "CAFE_DA_MANHA",
    almoco: "ALMOCO",
    jantar: "JANTAR"
  }

  validates :tipo_refeicao, :hora_inicio, :hora_fim, presence: true
  validates :tolerancia_atraso_min, :antecedencia_min,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :hora_inicio_menor_que_hora_fim
  validate :sem_conflito_de_horario

  def tipo_refeicao_label
    TIPO_LABELS[tipo_refeicao] || tipo_refeicao
  end

  private

  def hora_inicio_menor_que_hora_fim
    return if hora_inicio.blank? || hora_fim.blank?

    if hora_fim.strftime("%H:%M:%S") <= hora_inicio.strftime("%H:%M:%S")
      errors.add(:hora_fim, "deve ser posterior à hora de início")
    end
  end

  def sem_conflito_de_horario
    return if campus_id.blank? || hora_inicio.blank? || hora_fim.blank?

    inicio_str = hora_inicio.strftime("%H:%M:%S")
    fim_str = hora_fim.strftime("%H:%M:%S")

    conflito = Turno.where(campus_id: campus_id)
                    .where.not(id: id)
                    .where("hora_inicio < ? AND hora_fim > ?", fim_str, inicio_str)
                    .exists?

    errors.add(:base, "Conflito de horário com turno existente") if conflito
  end
end
