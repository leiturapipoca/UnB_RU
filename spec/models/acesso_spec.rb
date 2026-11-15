# frozen_string_literal: true

require "rails_helper"

RSpec.describe Acesso, type: :model do
  let(:campus) { Campus.create!(nome: "Darcy Ribeiro") }
  let(:restaurante) { Restaurante.create!(campus: campus, nome: "RU Central", piso: 1, capacidade_lugares: 500) }
  let(:catraca) { Catraca.create!(restaurante: restaurante, numero: 1, modo_operacional: "COMUM", status: "ONLINE") }
  let(:grupo_tarifario) { GrupoTarifario.create!(nome: "Grupo I") }

  let(:operador) do
    Funcionario.create!(
      siape: "3333333",
      nome: "Operador Catraca",
      senha_hash: "hash123",
      perfil: "OPERADOR",
      ativo: true
    )
  end

  let!(:sessao_operacao) do
    SessaoOperacao.create!(
      funcionario: operador,
      catraca: catraca,
      iniciada_em: Time.current,
      encerrada_em: nil
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
    Tarifa.create!(
      grupo_tarifario: grupo_tarifario,
      tipo_refeicao: "ALMOCO",
      valor: 2.50
    )
  end

  let(:estudante) do
    Estudante.create!(
      matricula: "242001508",
      nome: "Estudante Teste",
      senha_hash: "hash123",
      grupo_tarifario: grupo_tarifario,
      saldo: 30.00
    )
  end

  describe "associações e validações" do
    it "é válido com todos os atributos obrigatórios preenchidos" do
      acesso = Acesso.new(
        sessao_operacao: sessao_operacao,
        turno: turno,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: Time.current,
        modalidade: "COMUM",
        resultado: "LIBERADO"
      )

      expect(acesso).to be_valid
    end

    it "é inválido sem uma sessão de operação associada" do
      acesso = Acesso.new(
        sessao_operacao: nil,
        turno: turno,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: Time.current,
        modalidade: "COMUM",
        resultado: "LIBERADO"
      )

      expect(acesso).not_to be_valid
    end

    it "permite registrar acesso bloqueado quando não há turno ativo (fora de horário)" do
      acesso = Acesso.new(
        sessao_operacao: sessao_operacao,
        turno: nil,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: Time.current,
        modalidade: "COMUM",
        resultado: "LIBERADO"
      )

      expect(acesso).to be_valid
    end
  end

  describe "regras de negócio e triggers do banco" do
    it "persiste o acesso liberado e debita o valor da tarifa do saldo do estudante" do
      acesso = Acesso.create!(
        sessao_operacao: sessao_operacao,
        turno: turno,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: Time.current,
        modalidade: "COMUM",
        resultado: "LIBERADO"
      )

      expect(acesso).to be_persisted
      expect(acesso.reload.valor_cobrado.to_f).to eq(2.50)
      expect(estudante.reload.saldo.to_f).to eq(27.50)
    end

    it "rejeita o registro quando o estudante possui saldo insuficiente" do
      estudante.update!(saldo: 1.00)

      expect {
        Acesso.create!(
          sessao_operacao: sessao_operacao,
          turno: turno,
          estudante: estudante,
          identificacao_lida: estudante.matricula,
          data_hora: Time.current,
          modalidade: "COMUM",
          resultado: "LIBERADO"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /Saldo insuficiente/)

      expect(estudante.reload.saldo.to_f).to eq(1.00)
    end

    it "bloqueia entrada duplicada para o mesmo estudante, turno e data no fluxo online" do
      Acesso.create!(
        sessao_operacao: sessao_operacao,
        turno: turno,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: Time.current,
        modalidade: "COMUM",
        resultado: "LIBERADO"
      )

      expect {
        Acesso.create!(
          sessao_operacao: sessao_operacao,
          turno: turno,
          estudante: estudante,
          identificacao_lida: estudante.matricula,
          data_hora: Time.current,
          modalidade: "COMUM",
          resultado: "LIBERADO"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /Entrada já registrada/)
    end

    it "permite registrar histórico offline com timestamp de sincronização" do
      momento_sinc = Time.current
      acesso = Acesso.create!(
        sessao_operacao: sessao_operacao,
        turno: turno,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: 10.minutes.ago,
        modalidade: "COMUM",
        resultado: "LIBERADO",
        sincronizado_em: momento_sinc
      )

      expect(acesso).to be_persisted
      expect(acesso.sincronizado_em).to be_present
    end

    it "garante a imutabilidade do registro impedindo exclusão direta" do
      acesso = Acesso.create!(
        sessao_operacao: sessao_operacao,
        turno: turno,
        estudante: estudante,
        identificacao_lida: estudante.matricula,
        data_hora: Time.current,
        modalidade: "COMUM",
        resultado: "LIBERADO"
      )

      expect {
        acesso.destroy
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
