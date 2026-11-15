# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Cardapio, type: :model do
  let(:campus) { Campus.create!(nome: 'Campus Darcy Ribeiro') }
  let(:turno) { Turno.create!(campus: campus, tipo_refeicao: 'ALMOCO', hora_inicio: '11:00', hora_fim: '14:30') }

  let(:cardapio) do
    described_class.new(
      turno: turno,
      data: Date.current
    )
  end

  describe 'validações' do
    it 'é válido com todos os dados corretos' do
      expect(cardapio).to be_valid
    end

    it 'exige uma data' do
      cardapio.data = nil
      expect(cardapio).not_to be_valid
      expect(cardapio.errors[:data]).to be_present
    end

    it 'não permite cardápios duplicados para a mesma data e turno' do
      cardapio.save!

      outro_cardapio = described_class.new(turno: turno, data: cardapio.data)
      expect(outro_cardapio).not_to be_valid
      expect(outro_cardapio.errors[:data]).to be_present
    end
  end

  describe '.refeicao_atual' do
    before do
      cardapio.save!
    end

    it 'retorna o cardápio se houver um turno ativo no horário pesquisado' do
      hora_referencia = Time.zone.parse("#{Date.current} 12:00:00")
      expect(described_class.refeicao_atual(hora_referencia)).to eq(cardapio)
    end

    it 'retorna nil se o horário pesquisado estiver fora de todos os turnos' do

      hora_referencia = Time.zone.parse("#{Date.current} 09:00:00")

      expect(described_class.refeicao_atual(hora_referencia)).to be_nil
    end

    it 'retorna nil se o horário estiver no turno, mas não houver cardápio na data' do
      cardapio.destroy
      hora_referencia = Time.zone.parse("#{Date.current} 12:00:00")

      expect(described_class.refeicao_atual(hora_referencia)).to be_nil
    end
  end
end