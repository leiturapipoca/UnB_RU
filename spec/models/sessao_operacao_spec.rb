require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #5: a sessão de operação guarda em qual restaurante/catraca o funcionário trabalha
RSpec.describe SessaoOperacao, type: :model do
  include Ajudantes

  let(:restaurante) { criar_restaurante_com_catraca(nome: "RU Darcy") }
  let(:catraca) { restaurante.catracas.first }
  let(:funcionario) { criar_funcionario }

  def nova_sessao(atributos = {})
    described_class.new({ funcionario: funcionario, catraca: catraca, iniciada_em: 1.hour.ago }.merge(atributos))
  end

  it "é válida com os dados corretos" do
    expect(nova_sessao).to be_valid
  end

  it "exige o horário de início" do
    expect(nova_sessao(iniciada_em: nil)).not_to be_valid
  end

  it "não aceita encerramento antes do início" do
    sessao = nova_sessao(iniciada_em: Time.current, encerrada_em: 1.hour.ago)
    expect(sessao).not_to be_valid
    expect(sessao.errors[:encerrada_em]).to be_present
  end

  it "não aceita duas sessões abertas na mesma catraca" do
    nova_sessao.save!
    outro = criar_funcionario(siape: "7654321")

    segunda = nova_sessao(funcionario: outro)

    expect(segunda).not_to be_valid
    expect(segunda.errors[:catraca_id]).to be_present
  end

  it "não aceita duas sessões abertas para o mesmo funcionário" do
    nova_sessao.save!
    outra_catraca = restaurante.catracas.create!(numero: 2)

    segunda = nova_sessao(catraca: outra_catraca)

    expect(segunda).not_to be_valid
    expect(segunda.errors[:funcionario_id]).to be_present
  end

  it "permite abrir nova sessão depois de encerrar a anterior" do
    anterior = nova_sessao.tap(&:save!)
    anterior.update!(encerrada_em: Time.current)

    expect(nova_sessao(iniciada_em: Time.current)).to be_valid
  end
end
