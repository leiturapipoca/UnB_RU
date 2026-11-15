# frozen_string_literal: true

require "rails_helper"

RSpec.describe Turno, type: :model do
  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }

  it "é válido com atributos preenchidos e sem sobreposição de horário" do
    turno = Turno.new(campus: campus, tipo_refeicao: "ALMOCO", hora_inicio: "11:00:00", hora_fim: "14:30:00")
    expect(turno).to be_valid
  end

  it "permite turnos adjacentes que não se sobrepõem" do
    Turno.create!(campus: campus, tipo_refeicao: "ALMOCO", hora_inicio: "11:00:00", hora_fim: "14:30:00")
    jantar = Turno.new(campus: campus, tipo_refeicao: "JANTAR", hora_inicio: "14:30:00", hora_fim: "19:30:00")

    expect(jantar).to be_valid
  end

  it "rejeita turno com horário sobreposto a outro existente no mesmo campus" do
    Turno.create!(campus: campus, tipo_refeicao: "ALMOCO", hora_inicio: "11:00:00", hora_fim: "14:30:00")
    conflitante = Turno.new(campus: campus, tipo_refeicao: "ALMOCO", hora_inicio: "13:00:00", hora_fim: "15:00:00")

    expect(conflitante).not_to be_valid
    expect(conflitante.errors[:base]).to include("Conflito de horário com turno existente")
  end

  it "rejeita turno quando hora_fim é anterior ou igual a hora_inicio" do
    turno = Turno.new(campus: campus, tipo_refeicao: "JANTAR", hora_inicio: "19:00:00", hora_fim: "18:00:00")
    expect(turno).not_to be_valid
  end
end
