# frozen_string_literal: true

require "rails_helper"

RSpec.describe InscricaoFastpass, type: :model do
  let!(:campus) { Campus.find_or_create_by!(nome: "Campus Darcy Ribeiro") }
  let!(:grupo) { GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Isento" } }

  let!(:turno_almoco) do
    Turno.find_or_create_by!(campus: campus, tipo_refeicao: "ALMOCO") do |t|
      t.hora_inicio = "11:00"
      t.hora_fim = "14:00"
      t.fastpass_habilitado = true
    end
  end

  let!(:turno_jantar) do
    Turno.find_or_create_by!(campus: campus, tipo_refeicao: "JANTAR") do |t|
      t.hora_inicio = "17:30"
      t.hora_fim = "19:30"
      t.fastpass_habilitado = true
    end
  end

  let!(:janela_almoco_1) do
    JanelaFastpass.find_or_create_by!(turno: turno_almoco, hora_inicio: "11:00") do |j|
      j.hora_fim = "11:30"
      j.cota_vagas = 40
    end
  end

  let!(:janela_almoco_2) do
    JanelaFastpass.find_or_create_by!(turno: turno_almoco, hora_inicio: "11:30") do |j|
      j.hora_fim = "12:00"
      j.cota_vagas = 40
    end
  end

  let!(:janela_jantar) do
    JanelaFastpass.find_or_create_by!(turno: turno_jantar, hora_inicio: "17:30") do |j|
      j.hora_fim = "18:00"
      j.cota_vagas = 40
    end
  end

  let!(:sorteio_almoco) do
    Sorteio.find_or_create_by!(turno: turno_almoco, data: Date.current) do |s|
      s.data_hora_resultado = Time.current + 2.hours
      s.status = :inscricoes_abertas
    end
  end

  let!(:sorteio_jantar) do
    Sorteio.find_or_create_by!(turno: turno_jantar, data: Date.current) do |s|
      s.data_hora_resultado = Time.current + 6.hours
      s.status = :inscricoes_abertas
    end
  end

  let!(:estudante) do
    Estudante.find_or_create_by!(matricula: "231000777") do |e|
      e.nome = "Beatriz Martins"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
    end
  end

  before do
    described_class.where(estudante: estudante).delete_all
    sorteio_almoco.update!(status: :inscricoes_abertas)
  end

  describe "unicidade de inscrição por sorteio" do
    it "permite uma primeira inscrição válida" do
      inscricao = described_class.new(
        sorteio: sorteio_almoco,
        estudante: estudante,
        janela_fastpass: janela_almoco_1,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      expect(inscricao).to be_valid
    end

    it "bloqueia uma segunda inscrição do mesmo estudante no mesmo sorteio, mesmo em outra janela" do
      described_class.create!(
        sorteio: sorteio_almoco,
        estudante: estudante,
        janela_fastpass: janela_almoco_1,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      duplicada = described_class.new(
        sorteio: sorteio_almoco,
        estudante: estudante,
        janela_fastpass: janela_almoco_2,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      expect(duplicada).not_to be_valid
      expect(duplicada.errors.of_kind?(:estudante_id, :taken)).to be(true)
    end

    it "permite que o mesmo estudante se inscreva em sorteios de turnos diferentes" do
      described_class.create!(
        sorteio: sorteio_almoco,
        estudante: estudante,
        janela_fastpass: janela_almoco_1,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      outro_turno = described_class.new(
        sorteio: sorteio_jantar,
        estudante: estudante,
        janela_fastpass: janela_jantar,
        inscrito_em: Time.current,
        status: :aguardando_sorteio
      )

      expect(outro_turno).to be_valid
    end
  end

  describe "validade do código do passe" do
    it "rejeita código de passe enquanto aguarda sorteio" do
      inscricao = described_class.new(
        sorteio: sorteio_almoco,
        estudante: estudante,
        janela_fastpass: janela_almoco_1,
        inscrito_em: Time.current,
        status: :aguardando_sorteio,
        codigo_passe: "FP-12345"
      )

      expect(inscricao).not_to be_valid
      expect(inscricao.errors[:codigo_passe]).to be_present
    end
  end
end
