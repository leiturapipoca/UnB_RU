# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recarga, type: :model do
  let(:grupo) { GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Isento" } }
  let(:estudante) do
    Estudante.find_or_create_by!(matricula: "211000333") do |e|
      e.nome = "Aluno Teste Recarga"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
      e.saldo = 10.0
    end
  end

  before { estudante.update!(saldo: 10.0) }

  describe "validações" do
    it "é válida com atributos obrigatórios" do
      recarga = described_class.new(
        estudante: estudante,
        valor: 25.0,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current,
        codigo_transacao: "TRX-#{SecureRandom.hex(4)}"
      )

      expect(recarga).to be_valid
    end

    it "rejeita valor menor ou igual a zero" do
      recarga = described_class.new(
        estudante: estudante,
        valor: 0,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current
      )

      expect(recarga).not_to be_valid
    end
  end

  describe "integração com saldo (trigger fn_recarga_creditar)" do
    it "credita o valor no saldo do estudante ao confirmar a recarga" do
      recarga = described_class.create!(
        estudante: estudante,
        valor: 67.0,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current,
        codigo_transacao: "TRX-#{SecureRandom.hex(4)}"
      )

      expect(estudante.reload.saldo).to eq(10.0)

      recarga.update!(status: :confirmada, confirmada_em: Time.current)

      expect(estudante.reload.saldo).to eq(77.0)
    end

    it "não altera o saldo quando a recarga expira" do
      recarga = described_class.create!(
        estudante: estudante,
        valor: 50.0,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current,
        codigo_transacao: "TRX-#{SecureRandom.hex(4)}"
      )

      recarga.update!(status: :expirada)

      expect(estudante.reload.saldo).to eq(10.0)
    end
  end
end
