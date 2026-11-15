# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Extrato, type: :model do
  describe 'configurações do modelo' do
    it 'aponta para a tabela ou view correta no banco de dados' do
      expect(described_class.table_name).to eq('vw_extrato')
    end

    it 'é estritamente um modelo de leitura (readonly)' do
      extrato = described_class.new
      expect(extrato.readonly?).to be true
    end

    it 'impede a persistência de novos registros' do
      extrato = described_class.new(estudante_id: 1, valor: 10.0)

      expect {
        extrato.save
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end