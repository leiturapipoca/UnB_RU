# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sorteio, type: :model do
  let(:campus) { Campus.create!(nome: 'Campus Gama') }
  let(:turno) { Turno.create!(campus: campus, tipo_refeicao: 'JANTAR', hora_inicio: '17:00', hora_fim: '19:30') }

  let(:sorteio) do
    described_class.new(
      turno: turno,
      data: Date.current,
      data_hora_resultado: Time.current
    )
  end

  describe 'validações' do
    it 'é válido com todos os dados corretos' do
      expect(sorteio).to be_valid
    end

    it 'exige uma data' do
      sorteio.data = nil
      expect(sorteio).not_to be_valid
      expect(sorteio.errors[:data]).to be_present
    end

    it 'exige data_hora_resultado' do
      sorteio.data_hora_resultado = nil
      expect(sorteio).not_to be_valid
      expect(sorteio.errors[:data_hora_resultado]).to be_present
    end

    it 'não permite sorteios duplicados para a mesma data e turno' do
      sorteio.save!

      outro_sorteio = described_class.new(
        turno: turno,
        data: sorteio.data,
        data_hora_resultado: Time.current
      )
      expect(outro_sorteio).not_to be_valid
      expect(outro_sorteio.errors[:data]).to be_present
    end
  end

  describe 'enums' do
    it 'define o status inicial padrão e responde aos prefixos' do
      expect(sorteio.status_inscricoes_abertas?).to be true
      sorteio.status = 'REALIZADO'
      expect(sorteio.status_realizado?).to be true
      sorteio.status = 'CANCELADO'
      expect(sorteio.status_cancelado?).to be true
    end
  end
end