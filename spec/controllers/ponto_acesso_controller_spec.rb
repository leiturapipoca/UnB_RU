require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #5: Configuração de Ponto de Acesso (restaurante + catraca, logo após o login)
RSpec.describe PontoAcessoController, type: :controller do
  include Ajudantes

  let(:funcionario) { criar_funcionario }
  let!(:restaurante) { criar_restaurante_com_catraca(nome: "RU Darcy") }
  let(:catraca) { restaurante.catracas.first }

  it "manda para o login quem não está logado" do
    get :new
    expect(response).to redirect_to(login_path)
  end

  context "com funcionário logado" do
    before { session[:funcionario_id] = funcionario.id }

    describe "GET #new" do
      it "lista os restaurantes, inclusive os indisponíveis" do
        indisponivel = criar_restaurante_com_catraca(nome: "RU Fechado")
        indisponivel.update!(status: :indisponivel)

        get :new

        expect(response).to render_template(:new)
        expect(assigns(:restaurantes)).to include(restaurante, indisponivel)
      end
    end

    describe "POST #create" do
      context "com restaurante disponível" do
        before { post :create, params: { catraca_id: catraca.id } }

        it "abre a sessão de operação do funcionário naquela catraca" do
          sessao = SessaoOperacao.find_by!(funcionario: funcionario, encerrada_em: nil)
          expect(sessao.catraca).to eq(catraca)
          expect(session[:sessao_operacao_id]).to eq(sessao.id)
        end

        it "direciona para a tela principal" do
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to include("RU Darcy")
        end
      end

      context "com restaurante indisponível" do
        before do
          restaurante.update!(status: :indisponivel)
          post :create, params: { catraca_id: catraca.id }
        end

        it "mostra erro de indisponibilidade" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to include("não está disponível")
        end

        it "não grava nenhuma sessão de operação" do
          expect(SessaoOperacao.where(funcionario: funcionario)).to be_empty
          expect(session[:sessao_operacao_id]).to be_nil
        end
      end

      it "recusa catraca em manutenção" do
        catraca.update!(status: :manutencao)

        post :create, params: { catraca_id: catraca.id }

        expect(response).to have_http_status(:unprocessable_content)
        expect(SessaoOperacao.count).to eq(0)
      end

      it "pede para selecionar uma catraca quando nenhuma é enviada" do
        post :create

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash.now[:alert]).to eq("Selecione uma catraca")
      end

      it "recusa catraca que já está em uso por outro funcionário" do
        outro = criar_funcionario(siape: "7654321")
        SessaoOperacao.create!(funcionario: outro, catraca: catraca, iniciada_em: 1.hour.ago)

        post :create, params: { catraca_id: catraca.id }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash.now[:alert]).to include("já possui uma sessão aberta")
        expect(SessaoOperacao.where(funcionario: funcionario)).to be_empty
      end

      it "encerra a sessão anterior ao trocar de catraca" do
        segunda = restaurante.catracas.create!(numero: 2)
        anterior = SessaoOperacao.create!(funcionario: funcionario, catraca: catraca, iniciada_em: 1.hour.ago)

        post :create, params: { catraca_id: segunda.id }

        expect(anterior.reload.encerrada_em).to be_present
        expect(SessaoOperacao.where(funcionario: funcionario, encerrada_em: nil).pluck(:catraca_id)).to eq([ segunda.id ])
      end

      it "mantém a sessão anterior se a nova catraca estiver ocupada (tudo ou nada)" do
        segunda = restaurante.catracas.create!(numero: 2)
        outro = criar_funcionario(siape: "7654321")
        SessaoOperacao.create!(funcionario: outro, catraca: segunda, iniciada_em: 1.hour.ago)
        anterior = SessaoOperacao.create!(funcionario: funcionario, catraca: catraca, iniciada_em: 1.hour.ago)

        post :create, params: { catraca_id: segunda.id }

        expect(anterior.reload.encerrada_em).to be_nil
      end
    end
  end
end
