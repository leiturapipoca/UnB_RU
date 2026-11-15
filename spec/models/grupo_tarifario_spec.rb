# frozen_string_literal: true

require "rails_helper"

RSpec.describe GrupoTarifario, type: :model do
  describe "validações" do
    it "é válido com nome e descrição dentro dos limites" do
      grupo = described_class.new(
        nome: "Grupo Teste",
        descricao: "Estudantes com benefício parcial"
      )

      expect(grupo).to be_valid
    end

    it "é válido quando a descrição é nil" do
      grupo = described_class.new(nome: "Grupo Sem Desc", descricao: nil)

      expect(grupo).to be_valid
    end

    it "rejeita registro sem nome" do
      grupo = described_class.new(nome: nil, descricao: "Descrição")

      expect(grupo).not_to be_valid
      expect(grupo.errors.of_kind?(:nome, :blank)).to be(true)
    end

    it "rejeita nome duplicado" do
      described_class.create!(nome: "Grupo Unico", descricao: "Original")
      duplicado = described_class.new(nome: "Grupo Unico", descricao: "Cópia")

      expect(duplicado).not_to be_valid
      expect(duplicado.errors.of_kind?(:nome, :taken)).to be(true)
    end

    it "rejeita nome com mais de 20 caracteres" do
      grupo = described_class.new(nome: "A" * 21)

      expect(grupo).not_to be_valid
      expect(grupo.errors.of_kind?(:nome, :too_long)).to be(true)
    end

    it "rejeita descrição com mais de 200 caracteres" do
      grupo = described_class.new(nome: "Grupo Longo", descricao: "D" * 201)

      expect(grupo).not_to be_valid
      expect(grupo.errors.of_kind?(:descricao, :too_long)).to be(true)
    end
  end

  describe "associações e regras de exclusão" do
    it "remove as tarifas vinculadas ao excluir o grupo tarifário" do
      grupo = described_class.create!(nome: "Grupo Destroy", descricao: "Teste cascade")
      tarifa = Tarifa.create!(grupo_tarifario: grupo, tipo_refeicao: "ALMOCO", valor: 6.10)

      expect { grupo.destroy }.to change(Tarifa, :count).by(-1)
      expect(Tarifa.exists?(tarifa.id)).to be(false)
    end

    it "impede a exclusão quando existem estudantes vinculados" do
      grupo = described_class.create!(nome: "Grupo Restrict", descricao: "Com alunos")
      Estudante.create!(
        matricula: "239999001",
        nome: "Estudante Vinculado",
        senha_hash: "hash",
        grupo_tarifario: grupo
      )

      expect(grupo.destroy).to be(false)
      expect(grupo.errors[:base]).to be_present
      expect(described_class.exists?(grupo.id)).to be(true)
    end
  end
end
