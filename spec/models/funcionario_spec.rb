require "rails_helper"

RSpec.describe Funcionario, type: :model do
  let(:funcionario) do
    described_class.new(siape: "1234567", nome: "Maria", senha: "senha123", perfil: :operador)
  end

  it "é válido com dados corretos" do
    expect(funcionario).to be_valid
  end

  it "guarda só o hash da senha" do
    expect(funcionario.senha_hash).not_to eq("senha123")
    expect(funcionario.senha_confere?("senha123")).to be true
  end

  describe ".autenticar" do
    before { funcionario.save! }

    it "devolve o funcionário com credenciais certas" do
      expect(described_class.autenticar("1234567", "senha123")).to eq(funcionario)
    end

    it "nega senha errada" do
      expect(described_class.autenticar("1234567", "outra")).to be_nil
    end

    it "nega funcionário inativo" do
      funcionario.update!(ativo: false)
      expect(described_class.autenticar("1234567", "senha123")).to be_nil
    end
  end
end
