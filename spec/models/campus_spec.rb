# frozen_string_literal: true

require "rails_helper"

RSpec.describe Campus, type: :model do
  describe "validações" do
    it "é válido com um nome preenchido de até 80 caracteres" do
      campus = Campus.new(nome: "Darcy Ribeiro")
      expect(campus).to be_valid
    end

    it "é inválido sem nome" do
      campus = Campus.new(nome: nil)
      expect(campus).not_to be_valid
      expect(campus.errors[:nome]).to be_present
    end

    it "é inválido com nome duplicado" do
      Campus.create!(nome: "Darcy Ribeiro")
      duplicado = Campus.new(nome: "Darcy Ribeiro")

      expect(duplicado).not_to be_valid
      expect(duplicado.errors[:nome]).to be_present
    end

    it "é inválido quando o nome ultrapassa 80 caracteres" do
      campus = Campus.new(nome: "A" * 81)
      expect(campus).not_to be_valid
      expect(campus.errors[:nome]).to be_present
    end
  end

  describe "associações e restrições de exclusão" do
    let!(:campus) { Campus.create!(nome: "Gama") }

    it "impede a exclusão do campus quando possui restaurantes vinculados" do
      Restaurante.create!(
        campus: campus,
        nome: "RU Gama",
        piso: 1,
        capacidade_lugares: 300
      )

      expect(campus.destroy).to be_falsey
      expect(campus.errors[:base]).to be_present
      expect(Campus.exists?(campus.id)).to be(true)
    end

    it "impede a exclusão do campus quando possui turnos vinculados" do
      Turno.create!(
        campus: campus,
        tipo_refeicao: "ALMOCO",
        hora_inicio: "11:00:00",
        hora_fim: "14:00:00"
      )

      expect(campus.destroy).to be_falsey
      expect(campus.errors[:base]).to be_present
      expect(Campus.exists?(campus.id)).to be(true)
    end

    it "permite excluir o campus quando não possui restaurantes nem turnos associados" do
      expect { campus.destroy }.to change(Campus, :count).by(-1)
    end
  end
end
