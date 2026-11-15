require "rails_helper"
require Rails.root.join("features/support/ajudantes")

# Issues #4 e #5: a tela principal só abre para funcionário logado e com ponto de acesso escolhido
RSpec.describe PainelController, type: :controller do
  include Ajudantes

  let(:funcionario) { criar_funcionario }

  it "manda para o login quem não está logado" do
    get :index
    expect(response).to redirect_to(login_path)
  end

  it "manda escolher o restaurante quem está logado mas ainda não escolheu" do
    session[:funcionario_id] = funcionario.id

    get :index

    expect(response).to redirect_to(ponto_acesso_path)
  end

  it "abre a tela principal depois de escolher o ponto de acesso" do
    catraca = criar_restaurante_com_catraca.catracas.first
    sessao = SessaoOperacao.create!(funcionario: funcionario, catraca: catraca, iniciada_em: 1.hour.ago)
    session[:funcionario_id] = funcionario.id
    session[:sessao_operacao_id] = sessao.id

    get :index

    expect(response).to have_http_status(:ok)
    expect(response).to render_template(:index)
  end

  it "não aceita a sessão de operação de outro funcionário" do
    outro = criar_funcionario(siape: "7654321")
    catraca = criar_restaurante_com_catraca.catracas.first
    sessao_do_outro = SessaoOperacao.create!(funcionario: outro, catraca: catraca, iniciada_em: 1.hour.ago)
    session[:funcionario_id] = funcionario.id
    session[:sessao_operacao_id] = sessao_do_outro.id

    get :index

    expect(response).to redirect_to(ponto_acesso_path)
  end
end
