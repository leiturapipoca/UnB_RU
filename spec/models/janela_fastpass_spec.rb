require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Janela do FastPass: intervalo de horário, dentro de um turno, em que o aluno sorteado pode entrar.
RSpec.describe JanelaFastpass, type: :model do
  include Ajudantes

  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }
  # Almoço das 11:00 às 14:00
  let(:turno) do
    Turno.create!(campus: campus, tipo_refeicao: :almoco, hora_inicio: "11:00", hora_fim: "14:00",
                  fastpass_habilitado: true)
  end

  def nova_janela(atributos = {})
    described_class.new({ turno: turno, hora_inicio: "12:00", hora_fim: "12:15", cota_vagas: 10 }.merge(atributos))
  end

  describe "validações" do
    it "é válida com os dados corretos" do
      expect(nova_janela).to be_valid
    end

    it "exige turno" do
      janela = nova_janela(turno: nil)
      expect(janela).not_to be_valid
      expect(janela.errors[:turno]).to be_present
    end

    it "exige hora de início" do
      janela = nova_janela(hora_inicio: nil)
      expect(janela).not_to be_valid
      expect(janela.errors[:hora_inicio]).to be_present
    end

    it "exige hora de fim" do
      janela = nova_janela(hora_fim: nil)
      expect(janela).not_to be_valid
      expect(janela.errors[:hora_fim]).to be_present
    end

    describe "início anterior ao fim" do
      it "recusa início depois do fim" do
        janela = nova_janela(hora_inicio: "12:30", hora_fim: "12:00")
        expect(janela).not_to be_valid
        expect(janela.errors[:hora_inicio]).to include("deve ser anterior à hora fim")
      end

      it "recusa início igual ao fim" do
        expect(nova_janela(hora_inicio: "12:00", hora_fim: "12:00")).not_to be_valid
      end
    end

    describe "cota de vagas" do
      it "aceita zero (janela sem vagas)" do
        expect(nova_janela(cota_vagas: 0)).to be_valid
      end

      it "recusa cota negativa" do
        janela = nova_janela(cota_vagas: -1)
        expect(janela).not_to be_valid
        expect(janela.errors[:cota_vagas]).to be_present
      end

      it "exige a cota" do
        expect(nova_janela(cota_vagas: nil)).not_to be_valid
      end

      it "recusa texto no lugar do número" do
        expect(nova_janela(cota_vagas: "muitas")).not_to be_valid
      end
    end

    describe "ativa" do
      it "começa ativa por padrão" do
        janela = nova_janela
        janela.save!
        expect(janela.reload.ativa).to be true
      end

      it "aceita desativar" do
        expect(nova_janela(ativa: false)).to be_valid
      end

      it "não aceita valor em branco" do
        expect(nova_janela(ativa: nil)).not_to be_valid
      end
    end

    it "não aceita duas janelas com a mesma hora de início no mesmo turno" do
      nova_janela.save!

      repetida = nova_janela(hora_fim: "12:30")

      expect(repetida).not_to be_valid
      expect(repetida.errors[:hora_inicio]).to be_present
    end

    it "aceita janelas diferentes no mesmo turno, uma depois da outra" do
      nova_janela.save!

      expect(nova_janela(hora_inicio: "12:30", hora_fim: "12:45")).to be_valid
    end
  end

  # O banco é a segunda camada de proteção: vale mesmo se alguém pular as validações do Rails
  # (por exemplo, usando save(validate: false) ou escrevendo direto no SQL).
  describe "regras do banco de dados" do
    it "recusa janela que se sobrepõe a outra do mesmo turno" do
      nova_janela(hora_inicio: "12:00", hora_fim: "12:30").save!

      sobreposta = nova_janela(hora_inicio: "12:15", hora_fim: "12:45")

      expect(sobreposta).to be_valid # o Rails não percebe (hora de início diferente)
      expect { sobreposta.save! }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "aceita janelas encostadas (uma termina quando a outra começa)" do
      nova_janela(hora_inicio: "12:00", hora_fim: "12:15").save!

      expect { nova_janela(hora_inicio: "12:15", hora_fim: "12:30").save! }.not_to raise_error
    end

    it "recusa janela que começa antes do turno" do
      antes = nova_janela(hora_inicio: "10:30", hora_fim: "11:15")

      expect { antes.save! }.to raise_error(ActiveRecord::StatementInvalid, /Janela/)
    end

    it "recusa janela que termina depois do turno" do
      depois = nova_janela(hora_inicio: "13:50", hora_fim: "14:10")

      expect { depois.save! }.to raise_error(ActiveRecord::StatementInvalid, /Janela/)
    end

    it "aceita janela que ocupa o turno inteiro (limites exatos)" do
      inteira = nova_janela(hora_inicio: "11:00", hora_fim: "14:00")

      expect { inteira.save! }.not_to raise_error
    end

    it "recusa início depois do fim mesmo sem passar pelas validações do Rails" do
      invalida = nova_janela(hora_inicio: "13:00", hora_fim: "12:00")

      expect { invalida.save!(validate: false) }.to raise_error(ActiveRecord::CheckViolation)
    end

    it "recusa cota negativa mesmo sem passar pelas validações do Rails" do
      invalida = nova_janela(cota_vagas: -5)

      expect { invalida.save!(validate: false) }.to raise_error(ActiveRecord::CheckViolation)
    end
  end

  describe "associações" do
    it "pertence a um turno" do
      janela = nova_janela
      janela.save!

      expect(janela.reload.turno).to eq(turno)
      expect(turno.janelas_fastpass).to include(janela)
    end

    it "é removida junto com o turno" do
      janela = nova_janela
      janela.save!

      expect { turno.destroy! }.to change(described_class, :count).by(-1)
    end

    it "não pode ser removida enquanto houver inscrição nela" do
      montar_cenario_fastpass # cria turno, janela e uma inscrição contemplada
      janela = InscricaoFastpass.first.janela_fastpass

      expect(janela.destroy).to be false
      expect(janela.errors[:base]).to be_present
      expect(described_class.exists?(janela.id)).to be true
    end
  end
end
