# frozen_string_literal: true

require "rails_helper"

RSpec.describe AcessosController, type: :controller do
  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }
  let(:restaurante) { Restaurante.create!(campus: campus, nome: "RU Central", piso: 1, capacidade_lugares: 500) }
  let(:catraca) { Catraca.create!(restaurante: restaurante, numero: 1, modo_operacional: "COMUM", status: "ONLINE") }
  let(:funcionario) { Funcionario.create!(siape: "1234567", nome: "Operador", senha_hash: "hash123", perfil: "OPERADOR", ativo: true) }
  let(:grupo_tarifario) { GrupoTarifario.create!(nome: "Grupo I") }

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
    SessaoOperacao.create!(funcionario: funcionario, catraca: catraca, iniciada_em: Time.current, encerrada_em: nil)
  end

  let!(:estudante) do
    Estudante.create!(
      matricula: "242001508",
      nome: "Estudante Teste",
      senha_hash: "hash123",
      grupo_tarifario: grupo_tarifario,
      saldo: 20.0
    )
  end

  describe "GET #new" do
    it "renderiza o template de validação da catraca" do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create (Modo Online)" do
    context "quando a identificação é válida e há saldo" do
      it "libera a catraca, registra o acesso e debita o saldo via trigger" do
        expect {
          post :create, params: { identificacao: estudante.matricula }
        }.to change(Acesso, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(flash.now[:notice]).to eq("Catraca Liberada")
        expect(estudante.reload.saldo).to eq(17.50)
      end
    end

    context "quando a identificação não existe" do
      it "bloqueia a entrada e exibe Acesso Não Autorizado" do
        expect {
          post :create, params: { identificacao: "000000000" }
        }.not_to change(Acesso, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq("Acesso Não Autorizado")
      end
    end

    context "quando o estudante não possui saldo suficiente" do
      before { estudante.update!(saldo: 1.0) }

      it "bloqueia a entrada pela trigger do banco e exibe Acesso Não Autorizado" do
        expect {
          post :create, params: { identificacao: estudante.matricula }
        }.not_to change(Acesso, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq("Acesso Não Autorizado")
      end
    end

    context "quando o estudante tenta reutilizar a identificação no mesmo turno" do
      before do
        post :create, params: { identificacao: estudante.matricula }
      end

      it "bloqueia a segunda entrada e exibe Entrada já registrada" do
        expect {
          post :create, params: { identificacao: estudante.matricula }
        }.not_to change(Acesso, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq("Entrada já registrada")
      end
    end
  end

  describe "POST #create (Modo Offline / Histórico Local)" do
    before { session[:modo_offline] = true }

    context "quando um acesso válido é realizado sem conexão" do
      it "libera a catraca e armazena o evento no histórico local sem gravar no banco ainda" do
        expect {
          post :create, params: { identificacao: estudante.matricula }
        }.not_to change(Acesso, :count)

        expect(response).to have_http_status(:ok)
        expect(flash.now[:notice]).to eq("Catraca Liberada")
        expect(session[:historico_local].size).to eq(1)
        expect(session[:historico_local].first["matricula"]).to eq(estudante.matricula)
        expect(session[:historico_local].first["data_hora"]).to be_present
      end
    end

    context "quando a identificação não pode ser verificada localmente" do
      it "permanece bloqueada e exibe Validação indisponível offline" do
        expect {
          post :create, params: { identificacao: "" }
        }.not_to change(Acesso, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash.now[:alert]).to eq("Validação indisponível offline")
        expect(session[:historico_local]).to be_nil
      end
    end
  end

  describe "POST #sincronizar" do
    before do
      session[:modo_offline] = true
      session[:historico_local] = [
        { "matricula" => estudante.matricula, "data_hora" => 5.minutes.ago.iso8601 }
      ]
    end

    it "envia os registros locais para o banco central e limpa a memória local" do
      expect {
        post :sincronizar
      }.to change(Acesso, :count).by(1)

      acesso_criado = Acesso.last
      expect(acesso_criado.estudante_id).to eq(estudante.id)
      expect(acesso_criado.sincronizado_em).to be_present
      expect(session[:modo_offline]).to be(false)
      expect(session[:historico_local]).to be_empty
      expect(flash[:notice]).to eq("Sincronizado com sucesso: 1 acessos")
      expect(response).to redirect_to(catraca_validacao_path)
    end
  end
end
