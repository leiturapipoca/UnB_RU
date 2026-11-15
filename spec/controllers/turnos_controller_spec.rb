# frozen_string_literal: true

require "rails_helper"

RSpec.describe TurnosController, type: :controller do
  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }

  let(:gestor) do
    Funcionario.create!(
      siape: "1111111",
      nome: "Gestor Teste",
      senha_hash: "hash123",
      perfil: "GESTOR",
      ativo: true
    )
  end

  let(:operador) do
    Funcionario.create!(
      siape: "2222222",
      nome: "Operador Teste",
      senha_hash: "hash123",
      perfil: "OPERADOR",
      ativo: true
    )
  end

  describe "GET #new" do
    context "quando o gestor está logado" do
      before { session[:funcionario_id] = gestor.id }

      it "renderiza o formulário de configuração de turno" do
        get :new
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end

    context "quando o usuário logado não é gestor" do
      before { session[:funcionario_id] = operador.id }

      it "redireciona para a página inicial com alerta de acesso restrito" do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Acesso restrito a gestores")
      end
    end
  end

  describe "POST #create" do
    context "quando o gestor está logado" do
      before { session[:funcionario_id] = gestor.id }

      context "com horários válidos e sem conflito" do
        it "salva o turno, exibe mensagem de sucesso e redireciona" do
          expect {
            post :create, params: {
              turno: {
                tipo_refeicao: "ALMOCO",
                hora_inicio: "11:00",
                hora_fim: "14:30"
              }
            }
          }.to change(Turno, :count).by(1)

          expect(flash[:notice]).to eq("Turno cadastrado com sucesso")
          expect(response).to redirect_to(new_turno_path)
        end
      end

      context "com horários conflitantes com um turno existente" do
        before do
          Turno.create!(
            campus: campus,
            tipo_refeicao: "ALMOCO",
            hora_inicio: "11:00:00",
            hora_fim: "14:30:00"
          )
        end

        it "não salva o turno e exibe alerta de conflito de horário" do
          expect {
            post :create, params: {
              turno: {
                tipo_refeicao: "ALMOCO",
                hora_inicio: "12:30",
                hora_fim: "15:00"
              }
            }
          }.not_to change(Turno, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("Conflito de horário com turno existente")
        end
      end
    end

    context "quando o usuário não é gestor" do
      before { session[:funcionario_id] = operador.id }

      it "bloqueia a criação e redireciona para a página inicial" do
        expect {
          post :create, params: {
            turno: {
              tipo_refeicao: "JANTAR",
              hora_inicio: "17:30",
              hora_fim: "19:30"
            }
          }
        }.not_to change(Turno, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Acesso restrito a gestores")
      end
    end
  end
end