
require 'rails_helper'

RSpec.describe Estudante, type: :model do
  let(:grupo_tarifario) do
    GrupoTarifario.create!(nome: 'Grupo RSpec')
  end

  let(:estudante) do
    described_class.new(
      matricula: '242001508',
      nome: 'Estudante Teste',
      senha_hash: 'hash123',
      grupo_tarifario: grupo_tarifario
    )
  end

  describe 'validações' do
    it 'é válido com todos os dados corretos' do
      expect(estudante).to be_valid
    end

    it 'exige matrícula' do
      estudante.matricula = nil

      expect(estudante).not_to be_valid
      expect(estudante.errors[:matricula]).to be_present
    end

    it 'exige nome' do
      estudante.nome = nil

      expect(estudante).not_to be_valid
      expect(estudante.errors[:nome]).to be_present
    end

    it 'exige senha_hash' do
      estudante.senha_hash = nil

      expect(estudante).not_to be_valid
      expect(estudante.errors[:senha_hash]).to be_present
    end

    it 'não permite matrículas duplicadas' do
      estudante.save!

      outro_estudante = described_class.new(
        matricula: estudante.matricula,
        nome: 'Outro Estudante',
        senha_hash: 'hash456',
        grupo_tarifario: grupo_tarifario
      )

      expect(outro_estudante).not_to be_valid
      expect(outro_estudante.errors[:matricula]).to be_present
    end
  end
end
