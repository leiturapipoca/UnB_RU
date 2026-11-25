require "rails_helper"

# Login e logout do estudante
RSpec.describe "Sessão do estudante", type: :request do
  let(:grupo) { GrupoTarifario.create!(nome: "Grupo I") }
  let!(:estudante) do
    Estudante.create!(matricula: "221045999", nome: "Ana Beatriz",
                      senha_hash: BCrypt::Password.create("segredo1"), grupo_tarifario: grupo)
  end

  def entrar
    post login_estudante_path, params: { matricula: "221045999", senha: "segredo1" }
  end

  it "entra com matrícula e senha corretas" do
    entrar

    expect(response).to redirect_to(extrato_estudante_path(estudante))
    expect(session[:estudante_id]).to eq(estudante.id)
  end

  it "sai do sistema e volta para o login do estudante" do
    entrar

    delete logout_estudante_path

    expect(response).to redirect_to(login_estudante_path)
    expect(session[:estudante_id]).to be_nil
    follow_redirect!
    expect(response.body).to include("Você saiu do sistema")
  end

  it "depois de sair não abre mais o extrato" do
    entrar
    delete logout_estudante_path

    get extrato_estudante_path(estudante)

    expect(response).to redirect_to(login_estudante_path)
  end

  it "quem não está logado e tenta sair vai para o login do estudante" do
    delete logout_estudante_path

    expect(response).to redirect_to(login_estudante_path)
  end
end
