class Cardapio < ApplicationRecord
  self.table_name = "cardapios"
  belongs_to :turno
  has_many :itens_cardapio, dependent: :destroy
  validates :data, uniqueness: { scope: :turno_id }, presence: true

  # tlvz colocar um Time.now no refactor
  def self.refeicao_atual(hora_referencia = Time.current)
    # strftime transforma data em string formatada
    horario_formatado = hora_referencia.strftime("%H%M%S")

    # extrai somente a data pra auditabilidade
    data_atual = hora_referencia.to_date

    # puxa do bd o comeco e o fim de cada turno
    # o find_by retorna o primeiro registro que satisfaz a condicao, diferentemente do where
    turno_ativo = Turno.find_by("hora_inicio <= :hora AND hora_fim >= :hora", hora: horario_formatado)

    return nil unless turno_ativo
    # agr q ele tem a data e o turno procura qual o caradpio daquele dia
    find_by(turno_id: turno_ativo.id, data: data_atual)
  end
end
