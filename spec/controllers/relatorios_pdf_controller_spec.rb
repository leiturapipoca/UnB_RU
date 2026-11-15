# frozen_string_literal: true

require "rails_helper"

RSpec.describe RelatoriosController, type: :controller do
  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }
  let(:restaurante) { Restaurante.create!(campus: campus, nome: "RU Central", piso: 1, capacidade_lugares: 500) }
  let(:catraca) { Catraca.create!(restaurante: restaurante, numero: 1, modo_operacional: "COMUM", status: "ONLINE") }
  let(:grupo_tarifario) { GrupoTarifario.create!(nome: "Grupo I") }

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

  let!(:turno) do
    agora = Time.current
    Turno.create!(
      campus: campus,
      tipo_refeicao: "ALMOCO",
      hora_inicio: (agora - 1.hour).strftime("%H:%M:%S"),
      hora_fim: (agora + 1.hour).strftime("%H:%M:%S")
    )
  end

  let!(:tarifa) do
    Tarifa.create!(grupo_tarifario: grupo_tarifario, tipo_refeicao: "ALMOCO", valor: 2.50)
  end

  let!(:sessao_operacao) do
    SessaoOperacao.create!(funcionario: operador, catraca: catraca, iniciada_em: Time.current, encerrada_em: nil)
  end

  let!(:estudante) do
    Estudante.create!(
      matricula: "242001508",
      nome: "Estudante Teste",
      senha_hash: "hash123",
      grupo_tarifario: grupo_tarifario,
      saldo: 30.0
    )
  end

  describe "GET #index" do
    context "quando o gestor está logado" do
      before { session[:funcionario_id] = gestor.id }

      it "renderiza a tela de filtros do relatório" do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context "quando o usuário logado não é gestor" do
      before { session[:funcionario_id] = operador.id }

      it "redireciona para a página inicial com mensagem de acesso restrito" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Acesso restrito a gestores")
      end
    end

    context "quando não há funcionário logado" do
      it "redireciona para a página inicial com mensagem de acesso restrito" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Acesso restrito a gestores")
      end
    end
  end

  describe "GET #exportar" do
    context "quando o gestor está logado" do
      before { session[:funcionario_id] = gestor.id }

      context "e seleciona um período com movimentações" do
        let!(:acesso) do
          Acesso.create!(
            sessao_operacao: sessao_operacao,
            turno: turno,
            estudante: estudante,
            identificacao_lida: estudante.matricula,
            data_hora: Time.current,
            modalidade: "COMUM",
            resultado: "LIBERADO"
          )
        end

        it "gera o arquivo PDF e configura o download como attachment" do
          get :exportar, params: {
            data_inicio: Date.yesterday.to_s,
            data_fim: Date.tomorrow.to_s
          }, format: :pdf

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("application/pdf")
          expect(response.headers["Content-Disposition"]).to include("attachment")
        end
      end

      context "e seleciona um período sem registros" do
        it "não gera o PDF, redireciona e exibe aviso de período vazio" do
          get :exportar, params: {
            data_inicio: 10.days.ago.to_date.to_s,
            data_fim: 8.days.ago.to_date.to_s
          }, format: :pdf

          expect(response).to redirect_to(relatorios_path)
          expect(response.content_type).not_to include("application/pdf")
          expect(flash[:alert]).to eq("Nenhum registro encontrado para o período")
        end
      end
    end

    context "quando o usuário logado não é gestor" do
      before { session[:funcionario_id] = operador.id }

      it "bloqueia a exportação e redireciona para a página inicial" do
        get :exportar, params: {
          data_inicio: Date.yesterday.to_s,
          data_fim: Date.tomorrow.to_s
        }, format: :pdf

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Acesso restrito a gestores")
      end
    end
  end
end
