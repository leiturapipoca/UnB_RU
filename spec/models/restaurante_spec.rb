require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #8: Gestão de Restaurantes e Catracas
RSpec.describe Restaurante, type: :model do
  include Ajudantes

  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }
  let(:restaurante) { described_class.new(campus: campus, nome: "RU Darcy", piso: 1, capacidade_lugares: 300) }

  describe "validações" do
    it "é válido com os dados corretos" do
      expect(restaurante).to be_valid
    end

    it "exige nome" do
      restaurante.nome = nil
      expect(restaurante).not_to be_valid
      expect(restaurante.errors[:nome]).to be_present
    end

    it "exige campus" do
      restaurante.campus = nil
      expect(restaurante).not_to be_valid
    end

    it "exige piso maior ou igual a 1" do
      restaurante.piso = 0
      expect(restaurante).not_to be_valid
      expect(restaurante.errors[:piso]).to be_present
    end

    it "não aceita dois restaurantes com o mesmo nome no mesmo campus" do
      restaurante.save!
      repetido = described_class.new(campus: campus, nome: "RU Darcy", piso: 2)
      expect(repetido).not_to be_valid
      expect(repetido.errors[:nome]).to be_present
    end

    it "começa em operação por padrão" do
      restaurante.save!
      expect(restaurante.reload).to be_status_em_operacao
    end
  end

  describe "catracas no mesmo cadastro (nested attributes)" do
    it "salva o restaurante e a catraca juntos" do
      restaurante.catracas_attributes = [ { numero: 1, descricao: "Entrada principal" } ]

      expect { restaurante.save! }.to change(Catraca, :count).by(1)
      expect(restaurante.catracas.first.numero).to eq(1)
    end

    it "ignora a linha de catraca deixada em branco" do
      restaurante.catracas_attributes = [ { numero: "", descricao: "" } ]

      expect { restaurante.save! }.not_to change(Catraca, :count)
    end

    it "atualiza a catraca existente ao editar" do
      criado = criar_restaurante_com_catraca(nome: "RU Antigo")
      catraca = criado.catracas.first

      criado.update!(catracas_attributes: [ { id: catraca.id, numero: 7 } ])

      expect(catraca.reload.numero).to eq(7)
    end

    it "remove a catraca marcada para exclusão" do
      criado = criar_restaurante_com_catraca(nome: "RU Antigo")
      catraca = criado.catracas.first

      criado.update!(catracas_attributes: [ { id: catraca.id, _destroy: "1" } ])

      expect(Catraca.exists?(catraca.id)).to be false
    end
  end

  describe "remoção" do
    it "remove o restaurante e as catracas dele" do
      criado = criar_restaurante_com_catraca(nome: "RU Antigo")

      expect { criado.destroy! }.to change(Catraca, :count).by(-1)
      expect(described_class.exists?(criado.id)).to be false
    end

    it "não remove quando a catraca já tem sessão de operação (histórico)" do
      criado = criar_restaurante_com_catraca(nome: "RU Antigo")
      SessaoOperacao.create!(funcionario: criar_funcionario, catraca: criado.catracas.first, iniciada_em: 1.hour.ago)

      expect { criado.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(described_class.exists?(criado.id)).to be true
    end
  end
end
