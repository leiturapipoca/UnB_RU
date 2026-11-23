# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecargasController, type: :request do
  let(:grupo) { GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Isento" } }
  let(:estudante) do
    Estudante.find_or_create_by!(matricula: "211000444") do |e|
      e.nome = "Aluno Controller Recarga"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
      e.saldo = 10.0
    end
  end

  before do
    estudante.update!(saldo: 10.0)
    get test_login_path(estudante.id)
  end

  describe "GET /recargas/new" do
    it "renderiza o formulário de nova recarga para estudante autenticado" do
      get new_recarga_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /recargas" do
    it "cria uma recarga pendente e redireciona para detalhes" do
      expect do
        post recargas_path, params: { recarga: { valor: 67.0, metodo_pagamento: "PIX" } }
      end.to change(Recarga, :count).by(1)

      recarga = Recarga.order(:id).last
      expect(recarga.status).to eq("pendente")
      expect(response).to redirect_to(recarga_path(recarga))
    end

    it "exibe alerta quando nenhum método de pagamento é selecionado" do
      expect do
        post recargas_path, params: { recarga: { valor: 50.0 } }
      end.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Selecione um método de pagamento.")
    end

    it "bloqueia valores que arredondam para >= 10^8 sem estourar exceção de banco" do
      expect do
        post recargas_path, params: { recarga: { valor: "9999999999999999999999", metodo_pagamento: "PIX" } }
      end.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("menor que R$ 100.000.000,00")
    end
  end

  describe "PATCH /recargas/:id/confirmar" do
    it "confirma o pagamento e soma o valor ao saldo do estudante" do
      recarga = Recarga.create!(
        estudante: estudante,
        valor: 67.0,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current,
        codigo_transacao: "TRX-#{SecureRandom.hex(4)}"
      )

      patch confirmar_recarga_path(recarga)

      expect(recarga.reload.status).to eq("confirmada")
      expect(estudante.reload.saldo).to eq(77.0)
    end

    it "bloqueia a confirmação com alerta quando saldo + valor arredonda para >= 10^8" do
      estudante.update!(saldo: 50_000_000.00)
      recarga = Recarga.create!(
        estudante: estudante,
        valor: 49_999_999.99,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current,
        codigo_transacao: "TRX-#{SecureRandom.hex(4)}"
      )
      estudante.update!(saldo: 60_000_000.00)

      patch confirmar_recarga_path(recarga)

      expect(recarga.reload.status).to eq("pendente")
      expect(response).to redirect_to(recarga_path(recarga))
      expect(flash[:alert]).to include("limite máximo de R$ 99.999.999,99")
    end
  end

  describe "PATCH /recargas/:id/expirar" do
    it "marca como expirada, exibe alerta e mantém o saldo inalterado" do
      recarga = Recarga.create!(
        estudante: estudante,
        valor: 50.0,
        metodo_pagamento: :pix,
        status: :pendente,
        solicitada_em: Time.current,
        codigo_transacao: "TRX-#{SecureRandom.hex(4)}"
      )

      patch expirar_recarga_path(recarga)

      expect(recarga.reload.status).to eq("expirada")
      expect(estudante.reload.saldo).to eq(10.0)
      expect(flash[:alert]).to include("Erro ao efetivar pagamento")
    end
  end
end
