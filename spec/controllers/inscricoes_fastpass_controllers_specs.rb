# frozen_string_literal: true

require "rails_helper"

RSpec.describe InscricoesFastpassController, type: :request do
  let!(:campus) { Campus.find_or_create_by!(nome: "Campus Darcy Ribeiro") }
  let!(:grupo) { GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Isento" } }

  let!(:turno) do
    Turno.find_or_create_by!(campus: campus, tipo_refeicao: :almoco) do |t|
      t.hora_inicio = "11:00"
      t.hora_fim = "14:00"
      t.fastpass_habilitado = true
    end
  end

  let!(:janela1) do
    JanelaFastpass.find_or_create_by!(turno: turno, hora_inicio: "11:00") do |j|
      j.hora_fim = "11:30"
      j.cota_vagas = 40
    end
  end

  let!(:janela2) do
    JanelaFastpass.find_or_create_by!(turno: turno, hora_inicio: "11:30") do |j|
      j.hora_fim = "12:00"
      j.cota_vagas = 40
    end
  end

  let!(:sorteio) do
    Sorteio.find_or_create_by!(turno: turno, data: Date.current) do |s|
      s.data_hora_resultado = Time.current + 2.hours
      s.status = :inscricoes_abertas
    end
  end

  let!(:estudante) do
    Estudante.find_or_create_by!(matricula: "231000888") do |e|
      e.nome = "Rafael Costa"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
    end
  end

  before do
    InscricaoFastpass.where(estudante: estudante).delete_all
    sorteio.update!(status: :inscricoes_abertas)
    get test_login_path(estudante.id)
  end

  describe "GET /inscricoes_fastpass" do
    it "exibe a página de inscrições do estudante" do
      get inscricoes_fastpass_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /inscricoes_fastpass/nova" do
    it "oculta opções de time-frame e informa 'Inscrição já realizada' quando o estudante já está inscrito" do
      InscricaoFastpass.create!(
        sorteio: sorteio,
        estudante: estudante,
        janela_fastpass: janela1,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      get nova_inscricao_fastpass_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Inscrição já realizada")
      expect(response.body).not_to include("11:30 - 12:00")
    end
  end

  describe "POST /inscricoes_fastpass" do
    it "registra a primeira inscrição no sorteio e redireciona para a listagem" do
      expect do
        post inscricoes_fastpass_path, params: {
          inscricao_fastpass: { sorteio_id: sorteio.id, janela_fastpass_id: janela1.id }
        }
      end.to change(InscricaoFastpass, :count).by(1)

      expect(response).to redirect_to(inscricoes_fastpass_path)
      expect(flash[:notice]).to eq("Inscrição no FastPass realizada com sucesso!")
    end

    it "bloqueia tentativa de segunda inscrição no mesmo sorteio" do
      InscricaoFastpass.create!(
        sorteio: sorteio,
        estudante: estudante,
        janela_fastpass: janela1,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      expect do
        post inscricoes_fastpass_path, params: {
          inscricao_fastpass: { sorteio_id: sorteio.id, janela_fastpass_id: janela2.id }
        }
      end.not_to change(InscricaoFastpass, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Inscrição já realizada")
    end
  end
end
