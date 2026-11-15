# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemCardapio, type: :model do
  let!(:campus) { Campus.find_or_create_by!(nome: "Campus Darcy Ribeiro") }
  let!(:turno) do
    Turno.find_or_create_by!(campus: campus, tipo_refeicao: :almoco) do |t|
      t.hora_inicio = "11:00"
      t.hora_fim = "14:00"
    end
  end
  let!(:cardapio) do
    Cardapio.find_or_create_by!(turno: turno, data: Date.current + 7.days)
  end

  describe "validações" do
    it "é válido com todos os atributos obrigatórios preenchidos" do
      item = described_class.new(
        cardapio: cardapio,
        categoria: :prato_principal,
        opcao: :padrao,
        descricao: "Frango grelhado ao molho de ervas",
        ordem: 1
      )

      expect(item).to be_valid
    end

    it "rejeita item sem cardápio associado" do
      item = described_class.new(
        cardapio: nil,
        categoria: :bebida,
        opcao: :geral,
        descricao: "Suco de maracujá",
        ordem: 1
      )

      expect(item).not_to be_valid
      expect(item.errors[:cardapio]).to be_present
    end

    it "rejeita item sem descrição" do
      item = described_class.new(
        cardapio: cardapio,
        categoria: :salada,
        opcao: :geral,
        descricao: nil,
        ordem: 2
      )

      expect(item).not_to be_valid
      expect(item.errors.of_kind?(:descricao, :blank)).to be(true)
    end

    it "rejeita descrição com mais de 160 caracteres" do
      item = described_class.new(
        cardapio: cardapio,
        categoria: :guarnicao,
        opcao: :geral,
        descricao: "X" * 161,
        ordem: 3
      )

      expect(item).not_to be_valid
      expect(item.errors.of_kind?(:descricao, :too_long)).to be(true)
    end

    it "rejeita item sem ordem" do
      item = described_class.new(
        cardapio: cardapio,
        categoria: :sobremesa,
        opcao: :geral,
        descricao: "Doce de leite",
        ordem: nil
      )

      expect(item).not_to be_valid
      expect(item.errors.of_kind?(:ordem, :blank)).to be(true)
    end

    it "rejeita ordem não inteira" do
      item = described_class.new(
        cardapio: cardapio,
        categoria: :acompanhamento,
        opcao: :geral,
        descricao: "Arroz branco",
        ordem: 1.5
      )

      expect(item).not_to be_valid
      expect(item.errors.of_kind?(:ordem, :not_an_integer)).to be(true)
    end
  end

  describe "enums com prefixo" do
    it "mapeia categorias com prefixo :categoria" do
      item = described_class.new(
        cardapio: cardapio,
        categoria: :prato_principal,
        opcao: :vegetariano_estrito,
        descricao: "Quibe de abóbora com grão-de-bico",
        ordem: 1
      )

      expect(item.categoria_prato_principal?).to be(true)
      expect(item.opcao_vegetariano_estrito?).to be(true)
    end

    it "rejeita valores inválidos nos enums categoria e opcao" do
      expect do
        described_class.new(categoria: "INVALIDA")
      end.to raise_error(ArgumentError)

      expect do
        described_class.new(opcao: "INVALIDA")
      end.to raise_error(ArgumentError)
    end
  end
end
