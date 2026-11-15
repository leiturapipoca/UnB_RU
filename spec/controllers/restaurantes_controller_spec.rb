require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #8: Gestão de Restaurantes e Catracas (só administrador)
RSpec.describe RestaurantesController, type: :controller do
  include Ajudantes

  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }
  let(:administrador) { criar_funcionario(perfil: :administrador, siape: "1000001") }
  let(:operador) { criar_funcionario(perfil: :operador, siape: "1000002") }

  let(:parametros_validos) do
    {
      restaurante: {
        campus_id: campus.id, nome: "RU Darcy", piso: 1, capacidade_lugares: 300,
        catracas_attributes: { "0" => { numero: 1, descricao: "Entrada principal" } }
      }
    }
  end

  describe "controle de acesso" do
    it "manda para o login quem não está logado" do
      get :index
      expect(response).to redirect_to(login_path)
    end

    it "bloqueia o operador (não é administrador)" do
      session[:funcionario_id] = operador.id

      get :index

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito a administradores")
    end

    it "bloqueia o operador também ao tentar cadastrar" do
      session[:funcionario_id] = operador.id

      expect { post :create, params: parametros_validos }.not_to change(Restaurante, :count)
    end
  end

  context "como administrador" do
    before { session[:funcionario_id] = administrador.id }

    describe "GET #index" do
      it "lista os restaurantes" do
        restaurante = criar_restaurante_com_catraca(nome: "RU Antigo")

        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:restaurantes)).to include(restaurante)
      end
    end

    describe "GET #new" do
      it "prepara o formulário já com uma linha de catraca" do
        get :new

        expect(response).to render_template(:new)
        expect(assigns(:restaurante).catracas.size).to eq(1)
      end
    end

    describe "POST #create" do
      it "salva o restaurante e a catraca" do
        expect { post :create, params: parametros_validos }
          .to change(Restaurante, :count).by(1)
          .and change(Catraca, :count).by(1)

        expect(response).to redirect_to(restaurantes_path)
        expect(flash[:notice]).to eq("Restaurante cadastrado com sucesso")
      end

      it "mostra os erros e não salva quando faltam dados obrigatórios" do
        parametros_validos[:restaurante][:nome] = ""

        expect { post :create, params: parametros_validos }.not_to change(Restaurante, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
      end

      it "ignora campos que não estão liberados (strong parameters)" do
        parametros_validos[:restaurante][:id] = 999

        post :create, params: parametros_validos

        expect(Restaurante.find_by(nome: "RU Darcy").id).not_to eq(999)
      end
    end

    describe "PATCH #update" do
      let!(:restaurante) { criar_restaurante_com_catraca(nome: "RU Antigo") }

      it "atualiza o restaurante e a catraca" do
        catraca = restaurante.catracas.first

        patch :update, params: {
          id: restaurante.id,
          restaurante: { nome: "RU Novo", catracas_attributes: { "0" => { id: catraca.id, numero: 2 } } }
        }

        expect(response).to redirect_to(restaurantes_path)
        expect(restaurante.reload.nome).to eq("RU Novo")
        expect(catraca.reload.numero).to eq(2)
      end

      it "mostra os erros quando os dados são inválidos" do
        patch :update, params: { id: restaurante.id, restaurante: { piso: 0 } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
        expect(restaurante.reload.piso).to eq(1)
      end
    end

    describe "DELETE #destroy" do
      let!(:restaurante) { criar_restaurante_com_catraca(nome: "RU Antigo") }

      it "remove o restaurante e as catracas" do
        expect { delete :destroy, params: { id: restaurante.id } }
          .to change(Restaurante, :count).by(-1)
          .and change(Catraca, :count).by(-1)

        expect(response).to redirect_to(restaurantes_path)
        expect(flash[:notice]).to eq("Restaurante removido com sucesso")
      end

      it "não remove restaurante com histórico de sessões e avisa o administrador" do
        SessaoOperacao.create!(
          funcionario: operador, catraca: restaurante.catracas.first, iniciada_em: 1.hour.ago
        )

        expect { delete :destroy, params: { id: restaurante.id } }.not_to change(Restaurante, :count)

        expect(response).to redirect_to(restaurantes_path)
        expect(flash[:alert]).to include("Não é possível remover")
      end
    end
  end
end
