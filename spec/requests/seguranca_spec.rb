require "rails_helper"

# Garante que dados de estudantes não ficam expostos a quem não deve vê-los
RSpec.describe "Segurança dos dados de estudantes", type: :request do
  let(:grupo) { GrupoTarifario.create!(nome: "Grupo I") }

  def criar_estudante(matricula, nome)
    Estudante.create!(matricula: matricula, nome: nome, senha_hash: "hash", grupo_tarifario: grupo)
  end

  def criar_funcionario(perfil, siape)
    Funcionario.create!(siape: siape, nome: "Funcionário #{perfil}", senha: "senha123", perfil: perfil)
  end

  def entrar_como(funcionario)
    post login_path, params: { siape: funcionario.siape, senha: "senha123" }
  end

  describe "relatório global de acessos" do
    it "manda para o login quem não está logado" do
      get relatorio_global_acessos_path

      expect(response).to redirect_to(login_path)
    end

    it "bloqueia o operador" do
      entrar_como(criar_funcionario(:operador, "1000001"))

      get relatorio_global_acessos_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito a gestores e administradores")
    end

    it "libera o administrador" do
      entrar_como(criar_funcionario(:administrador, "1000002"))

      get relatorio_global_acessos_path

      expect(response).to have_http_status(:ok)
    end

    it "libera o gestor" do
      entrar_como(criar_funcionario(:gestor, "1000003"))

      get relatorio_global_acessos_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "menu do funcionário" do
    it "não mostra o relatório global ao operador" do
      entrar_como(criar_funcionario(:operador, "1000004"))

      get ponto_acesso_path

      expect(response.body).not_to include("Relatório global")
    end

    it "mostra o relatório global ao administrador" do
      entrar_como(criar_funcionario(:administrador, "1000005"))

      get ponto_acesso_path

      expect(response.body).to include("Relatório global")
    end

    it "mostra Turnos e Relatórios só ao gestor, e Restaurantes só ao administrador" do
      entrar_como(criar_funcionario(:gestor, "1000006"))
      get ponto_acesso_path
      expect(response.body).to include("Turnos")
      expect(response.body).not_to include("Restaurantes")

      delete logout_path
      entrar_como(criar_funcionario(:administrador, "1000007"))
      get ponto_acesso_path
      expect(response.body).to include("Restaurantes")
      expect(response.body).not_to include("Turnos")
    end
  end

  describe "cadastro de estudante" do
    it "guarda só o hash da senha, nunca o texto digitado" do
      post estudantes_path, params: { estudante: { matricula: "221045999", nome: "Ana Beatriz", senha_hash: "minhaSenha1" } }

      estudante = Estudante.find_by!(matricula: "221045999")
      expect(estudante.senha_hash).not_to eq("minhaSenha1")
      expect(BCrypt::Password.new(estudante.senha_hash)).to eq("minhaSenha1")
    end

    it "continua recusando o cadastro sem senha" do
      expect {
        post estudantes_path, params: { estudante: { matricula: "221045999", nome: "Ana Beatriz", senha_hash: "" } }
      }.not_to change(Estudante, :count)
    end
  end

  describe "extrato do estudante" do
    let!(:ana) { criar_estudante("221045999", "Ana Beatriz") }
    let!(:bia) { criar_estudante("221045888", "Bia Souza") }

    it "mostra o próprio extrato" do
      get test_login_path(ana.id)

      get extrato_estudante_path(ana)

      expect(response).to have_http_status(:ok)
    end

    it "recusa o extrato de outro estudante e volta para o próprio" do
      get test_login_path(ana.id)

      get extrato_estudante_path(bia)

      expect(response).to redirect_to(extrato_estudante_path(ana))
      follow_redirect!
      expect(response.body).to include("Você só pode ver o seu próprio extrato")
    end

    it "manda para o login quem não está logado" do
      get extrato_estudante_path(ana)

      expect(response).to redirect_to(login_path)
    end
  end
end
