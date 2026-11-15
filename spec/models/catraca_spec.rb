require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #8: catracas físicas do restaurante
RSpec.describe Catraca, type: :model do
  include Ajudantes

  let(:restaurante) { criar_restaurante_com_catraca(nome: "RU Darcy") }

  def nova_catraca(atributos = {})
    described_class.new({ restaurante: restaurante, numero: 2 }.merge(atributos))
  end

  it "é válida com os dados corretos" do
    expect(nova_catraca).to be_valid
  end

  it "exige número maior que zero" do
    expect(nova_catraca(numero: 0)).not_to be_valid
  end

  it "não aceita número repetido no mesmo restaurante" do
    repetida = nova_catraca(numero: restaurante.catracas.first.numero)
    expect(repetida).not_to be_valid
    expect(repetida.errors[:numero]).to be_present
  end

  it "aceita o mesmo número em outro restaurante" do
    restaurante # cria o "RU Darcy" com a catraca 1
    criar_restaurante_com_catraca(nome: "RU Outro") # também com a catraca 1

    expect(described_class.where(numero: 1).count).to eq(2)
  end

  it "usa modo comum e status offline por padrão" do
    catraca = nova_catraca
    catraca.save!
    expect(catraca.reload).to be_modo_comum
    expect(catraca).to be_status_offline
  end

  it "limita a descrição a 80 caracteres" do
    expect(nova_catraca(descricao: "x" * 81)).not_to be_valid
  end
end
