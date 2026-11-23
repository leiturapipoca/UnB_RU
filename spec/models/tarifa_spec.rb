require "rails_helper"

# Tarifa: quanto cada grupo tarifário paga por tipo de refeição.
# O banco lê esse valor ao liberar uma entrada e debita do saldo do estudante.
RSpec.describe Tarifa, type: :model do
  let(:grupo) { GrupoTarifario.create!(nome: "Grupo I") }

  def nova_tarifa(atributos = {})
    described_class.new({ grupo_tarifario: grupo, tipo_refeicao: :almoco, valor: 5.00 }.merge(atributos))
  end

  describe "validações" do
    it "é válida com os dados corretos" do
      expect(nova_tarifa).to be_valid
    end

    it "exige grupo tarifário" do
      tarifa = nova_tarifa(grupo_tarifario: nil)
      expect(tarifa).not_to be_valid
      expect(tarifa.errors[:grupo_tarifario]).to be_present
    end

    describe "valor" do
      it "aceita zero (refeição gratuita, como o grupo isento)" do
        expect(nova_tarifa(valor: 0)).to be_valid
      end

      it "aceita valor com centavos" do
        expect(nova_tarifa(valor: 2.50)).to be_valid
      end

      it "recusa valor negativo" do
        tarifa = nova_tarifa(valor: -1)
        expect(tarifa).not_to be_valid
        expect(tarifa.errors[:valor]).to be_present
      end

      it "exige o valor" do
        expect(nova_tarifa(valor: nil)).not_to be_valid
      end

      it "recusa texto no lugar do número" do
        expect(nova_tarifa(valor: "caro")).not_to be_valid
      end

      it "guarda como decimal (BigDecimal), sem erro de arredondamento de float" do
        tarifa = nova_tarifa(valor: 2.50)
        tarifa.save!

        expect(tarifa.reload.valor).to be_a(BigDecimal)
        expect(tarifa.valor).to eq(BigDecimal("2.50"))
      end
    end

    describe "unicidade por grupo e refeição" do
      before { nova_tarifa.save! }

      it "não aceita duas tarifas da mesma refeição para o mesmo grupo" do
        repetida = nova_tarifa(valor: 9.99)

        expect(repetida).not_to be_valid
        expect(repetida.errors[:tipo_refeicao]).to be_present
      end

      it "aceita a mesma refeição em outro grupo" do
        outro_grupo = GrupoTarifario.create!(nome: "Grupo II")

        expect(nova_tarifa(grupo_tarifario: outro_grupo)).to be_valid
      end

      it "aceita outra refeição no mesmo grupo" do
        expect(nova_tarifa(tipo_refeicao: :jantar)).to be_valid
      end

      it "permite uma tarifa para cada refeição do grupo (café, almoço e jantar)" do
        nova_tarifa(tipo_refeicao: :cafe_da_manha).save!
        nova_tarifa(tipo_refeicao: :jantar).save!

        expect(grupo.tarifas.count).to eq(3)
      end
    end
  end

  describe "tipo de refeição (enum)" do
    it "oferece perguntas com o prefixo tipo_" do
      tarifa = nova_tarifa(tipo_refeicao: :jantar)

      expect(tarifa).to be_tipo_jantar
      expect(tarifa).not_to be_tipo_almoco
    end

    it "grava no banco o texto em maiúsculas que o banco espera" do
      tarifa = nova_tarifa(tipo_refeicao: :cafe_da_manha)
      tarifa.save!

      gravado = described_class.connection.select_value("SELECT tipo_refeicao FROM tarifas WHERE id = #{tarifa.id}")
      expect(gravado).to eq("CAFE_DA_MANHA")
    end

    it "não aceita um tipo que não existe" do
      expect { nova_tarifa(tipo_refeicao: :lanche) }.to raise_error(ArgumentError)
    end
  end

  # O banco é a segunda camada de proteção: vale mesmo se alguém pular as validações do Rails.
  describe "regras do banco de dados" do
    it "recusa valor negativo mesmo sem passar pelas validações do Rails" do
      expect { nova_tarifa(valor: -1).save!(validate: false) }.to raise_error(ActiveRecord::CheckViolation)
    end

    it "recusa tarifa sem tipo de refeição" do
      expect { nova_tarifa(tipo_refeicao: nil).save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "recusa tarifa repetida mesmo sem passar pelas validações do Rails" do
      nova_tarifa.save!

      expect { nova_tarifa(valor: 7).save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "associações" do
    it "pertence a um grupo tarifário" do
      tarifa = nova_tarifa
      tarifa.save!

      expect(tarifa.reload.grupo_tarifario).to eq(grupo)
      expect(grupo.tarifas).to include(tarifa)
    end

    it "é removida junto com o grupo tarifário" do
      nova_tarifa.save!

      expect { grupo.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
