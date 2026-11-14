require "rails_helper"
require Rails.root.join("features/support/ajudantes")

RSpec.describe ValidadorFastpass do
  include Ajudantes
  include ActiveSupport::Testing::TimeHelpers

  before { montar_cenario_fastpass(saldo: 10) }
  after  { travel_back }

  def validar(codigo = "PASSE123")
    described_class.new(sessao_operacao: @sessao, codigo_passe: codigo).validar
  end

  it "libera, registra o acesso e debita o saldo quando chega na janela" do
    travel_to @dia.change(hour: 12, min: 5)

    resultado = validar

    expect(resultado).to be_liberado
    expect(@estudante.reload.saldo).to eq(5)
    expect(@inscricao.reload).to be_status_utilizada
  end

  it "bloqueia quando chega atrasado" do
    travel_to @dia.change(hour: 12, min: 40)

    resultado = validar

    expect(resultado.motivo).to eq(:fora_da_janela)
    expect(@estudante.reload.saldo).to eq(10)
  end

  it "bloqueia por saldo insuficiente" do
    @estudante.update!(saldo: 1)
    travel_to @dia.change(hour: 12, min: 5)

    expect(validar.motivo).to eq(:saldo_insuficiente)
  end

  it "bloqueia passe inexistente" do
    travel_to @dia.change(hour: 12, min: 5)

    expect(validar("NAOEXISTE").motivo).to eq(:sem_fastpass)
  end
end
