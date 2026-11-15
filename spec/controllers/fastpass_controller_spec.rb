require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issue #16: Validação Rigorosa FastPass (tela onde o operador lê o passe)
RSpec.describe FastpassController, type: :controller do
  include Ajudantes
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  it "manda para o login quem não está logado" do
    get :new
    expect(response).to redirect_to(login_path)
  end

  it "manda escolher o ponto de acesso quem ainda não escolheu" do
    session[:funcionario_id] = criar_funcionario.id

    get :new

    expect(response).to redirect_to(ponto_acesso_path)
  end

  context "com funcionário logado e ponto de acesso escolhido" do
    before do
      montar_cenario_fastpass(saldo: 10) # define @sessao, @estudante, @inscricao, @dia
      session[:funcionario_id] = @sessao.funcionario_id
      session[:sessao_operacao_id] = @sessao.id
    end

    it "mostra a tela de leitura do passe" do
      get :new
      expect(response).to render_template(:new)
    end

    it "libera a entrada e debita o saldo quando o aluno chega no horário" do
      travel_to @dia.change(hour: 12, min: 5)

      post :create, params: { codigo_passe: "PASSE123" }

      expect(response).to redirect_to(fastpass_path)
      expect(flash[:notice]).to eq("Entrada liberada")
      expect(@estudante.reload.saldo).to eq(5)
    end

    it "bloqueia a entrada quando o aluno chega atrasado" do
      travel_to @dia.change(hour: 12, min: 40)

      post :create, params: { codigo_passe: "PASSE123" }

      expect(response).to redirect_to(fastpass_path)
      expect(flash[:alert]).to eq("Entrada bloqueada: Fora da janela")
      expect(@estudante.reload.saldo).to eq(10)
    end

    it "bloqueia código de passe que não existe" do
      travel_to @dia.change(hour: 12, min: 5)

      post :create, params: { codigo_passe: "INEXISTENTE" }

      expect(flash[:alert]).to eq("Entrada bloqueada: Sem fastpass")
    end

    it "registra o acesso bloqueado, com o motivo" do
      travel_to @dia.change(hour: 12, min: 40)

      expect { post :create, params: { codigo_passe: "PASSE123" } }.to change(Acesso, :count).by(1)

      acesso = Acesso.order(:data_hora).last
      expect(acesso).to be_resultado_bloqueado
      expect(acesso).to be_motivo_fora_da_janela
    end
  end
end
