# frozen_string_literal: true

class Turno < ApplicationRecord
  belongs_to :campus
  has_many :acessos
  has_many :janelas_fastpass, class_name: "JanelaFastpass", dependent: :destroy

  enum :tipo_refeicao, {
    cafe_da_manha: "CAFE_DA_MANHA",
    almoco: "ALMOCO",
    jantar: "JANTAR"
  }

  validates :tipo_refeicao, :hora_inicio, :hora_fim, presence: true
  validate :hora_inicio_menor_que_hora_fim
  validate :sem_conflito_de_horario

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