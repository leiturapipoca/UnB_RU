require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #4: Autenticação do Funcionário
RSpec.describe SessoesController, type: :controller do
  include Ajudantes

  describe "GET #new" do
    it "mostra a tela de login para quem não está logado" do
      get :new
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end

    it "manda para a tela principal quem já está logado" do
      funcionario = criar_funcionario
      session[:funcionario_id] = funcionario.id

      get :new

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST #create" do
    let!(:funcionario) { criar_funcionario(siape: "1234567", senha: "senha123") }

    context "com credenciais válidas" do
      before { post :create, params: { siape: "1234567", senha: "senha123" } }

      it "autentica a sessão do funcionário" do
        expect(session[:funcionario_id]).to eq(funcionario.id)
      end

      it "leva para a escolha do restaurante" do
        expect(response).to redirect_to(ponto_acesso_path)
      end
    end

    context "com senha errada" do
      before { post :create, params: { siape: "1234567", senha: "errada" } }

      it "não autentica" do
        expect(session[:funcionario_id]).to be_nil
      end

      it "mostra mensagem de erro e não redireciona" do
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(flash.now[:alert]).to eq("SIAPE ou senha inválidos")
      end
    end

    context "com SIAPE inexistente" do
      it "usa a mesma mensagem (não revela se o SIAPE existe)" do
        post :create, params: { siape: "9999999", senha: "senha123" }

        expect(session[:funcionario_id]).to be_nil
        expect(flash.now[:alert]).to eq("SIAPE ou senha inválidos")
      end
    end

    context "com funcionário inativo" do
      it "não autentica mesmo com a senha certa" do
        funcionario.update!(ativo: false)

        post :create, params: { siape: "1234567", senha: "senha123" }

        expect(session[:funcionario_id]).to be_nil
      end
    end

    it "descarta a sessão anterior ao entrar (evita fixação de sessão)" do
      session[:lixo] = "dado da sessão antiga"

      post :create, params: { siape: "1234567", senha: "senha123" }

      expect(session[:lixo]).to be_nil
    end
  end

  describe "DELETE #destroy" do
    let(:funcionario) { criar_funcionario }

    it "exige estar logado" do
      delete :destroy
      expect(response).to redirect_to(login_path)
    end

    it "encerra a sessão de operação e a sessão do funcionário" do
      catraca = criar_restaurante_com_catraca.catracas.first
      sessao = SessaoOperacao.create!(funcionario: funcionario, catraca: catraca, iniciada_em: 1.hour.ago)
      session[:funcionario_id] = funcionario.id
      session[:sessao_operacao_id] = sessao.id

      delete :destroy

      expect(sessao.reload.encerrada_em).to be_present
      expect(session[:funcionario_id]).to be_nil
      expect(response).to redirect_to(login_path)
    end
  end
end
