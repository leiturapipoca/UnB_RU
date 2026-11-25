# frozen_string_literal: true

class JanelaFastpass < ApplicationRecord
  self.table_name = "janelas_fastpass"

  belongs_to :turno
  has_many :inscricoes_fastpass, dependent: :restrict_with_error

  validates :hora_inicio, uniqueness: { scope: :turno_id }, presence: true
  validates :hora_fim, presence: true
  validates :cota_vagas, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :ativa, inclusion: { in: [ true, false ] }
  validate :hora_inicio_menor_que_hora_fim
  validate :dentro_do_horario_do_turno
  validate :sem_sobreposicao_de_horario

  def horario_formatado
    "#{hora_inicio.strftime('%H:%M')} - #{hora_fim.strftime('%H:%M')}"
  end

  private

  def hora_inicio_menor_que_hora_fim
    return if hora_inicio.blank? || hora_fim.blank?

    if hora_inicio.strftime("%H:%M:%S") >= hora_fim.strftime("%H:%M:%S")
      errors.add(:hora_inicio, "deve ser anterior à hora fim")
    end
  end

  def dentro_do_horario_do_turno
    return if turno.blank? || hora_inicio.blank? || hora_fim.blank?
    return if turno.hora_inicio.blank? || turno.hora_fim.blank?

    if hora_inicio.strftime("%H:%M:%S") < turno.hora_inicio.strftime("%H:%M:%S") ||
       hora_fim.strftime("%H:%M:%S") > turno.hora_fim.strftime("%H:%M:%S")
      errors.add(:base, "O time-frame deve estar dentro do horário do turno (#{turno.hora_inicio.strftime('%H:%M')} - #{turno.hora_fim.strftime('%H:%M')})")
    end
  end

  def sem_sobreposicao_de_horario
    return if turno_id.blank? || hora_inicio.blank? || hora_fim.blank?

    conflito = JanelaFastpass.where(turno_id: turno_id)
                             .where.not(id: id)
                             .where("hora_inicio < ? AND hora_fim > ?",
                                    hora_fim.strftime("%H:%M:%S"),
                                    hora_inicio.strftime("%H:%M:%S"))
                             .exists?

    errors.add(:base, "Conflito de horário com outro time-frame deste turno") if conflito
  end
end
