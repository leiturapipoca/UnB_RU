# frozen_string_literal: true

require "rails_helper"

RSpec.describe RelatoriosController, type: :request do
  let!(:campus) { Campus.find_or_create_by!(nome: "Campus Darcy Ribeiro") }
  let!(:grupo) { GrupoTarifario.find_or_create_by!(nome: "Grupo I") { |g| g.descricao = "Isento" } }
  let!(:turno) do
    Turno.find_or_create_by!(campus: campus, tipo_refeicao: "ALMOCO") do |t|
      t.hora_inicio = "11:00"
      t.hora_fim = "14:00"
    end
  end
  let!(:tarifa) do
    Tarifa.find_or_create_by!(grupo_tarifario: grupo, tipo_refeicao: "ALMOCO") { |tf| tf.valor = 0.0 }
  end

  let!(:restaurante1) { Restaurante.find_or_create_by!(campus: campus, nome: "Restaurante 1") { |r| r.piso = 1 } }
  let!(:restaurante4) { Restaurante.find_or_create_by!(campus: campus, nome: "Restaurante 4") { |r| r.piso = 1 } }

  let!(:catraca1) do
    Catraca.find_or_create_by!(restaurante: restaurante1, numero: 1) { |c| c.descricao = "Catraca 1" }
  end
  let!(:catraca2) do
    Catraca.find_or_create_by!(restaurante: restaurante1, numero: 2) { |c| c.descricao = "Catraca 2" }
  end
  let!(:catraca_r4) do
    Catraca.find_or_create_by!(restaurante: restaurante4, numero: 1) { |c| c.descricao = "Catraca 1" }
  end

  let!(:func1) do
    Funcionario.find_or_create_by!(siape: "1000001") do |f|
      f.nome = "Operador 1"
      f.senha_hash = "hash"
      f.perfil = :operador
      f.ativo = true
    end
  end
  let!(:func2) do
    Funcionario.find_or_create_by!(siape: "1000002") do |f|
      f.nome = "Operador 2"
      f.senha_hash = "hash"
      f.perfil = :operador
      f.ativo = true
    end
  end

  let!(:sessao1) do
    SessaoOperacao.find_by(catraca: catraca1, encerrada_em: nil) ||
      SessaoOperacao.create!(catraca: catraca1, funcionario: func1, iniciada_em: Time.current)
  end
  let!(:sessao2) do
    SessaoOperacao.find_by(catraca: catraca2, encerrada_em: nil) ||
      SessaoOperacao.create!(catraca: catraca2, funcionario: func2, iniciada_em: Time.current)
  end

  let!(:estudante_c1) do
    Estudante.find_or_create_by!(matricula: "211000111") do |e|
      e.nome = "Mariana Souza"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
    end
  end
  let!(:estudante_c2) do
    Estudante.find_or_create_by!(matricula: "211000222") do |e|
      e.nome = "Carlos Pereira"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
    end
  end

  before do
    unless Acesso.exists?(estudante: estudante_c1, turno: turno)
      Acesso.create!(
        sessao_operacao: sessao1,
        turno: turno,
        estudante: estudante_c1,
        identificacao_lida: estudante_c1.matricula.strip,
        data_hora: Time.current,
        modalidade: :comum,
        resultado: :liberado,
        valor_cobrado: 0.0
      )
    end

    unless Acesso.exists?(estudante: estudante_c2, turno: turno)
      Acesso.create!(
        sessao_operacao: sessao2,
        turno: turno,
        estudante: estudante_c2,
        identificacao_lida: estudante_c2.matricula.strip,
        data_hora: Time.current,
        modalidade: :comum,
        resultado: :liberado,
        valor_cobrado: 0.0
      )
    end
  end

  describe "GET /relatorio_global_acessos" do
    it "filtra apenas os acessos da catraca e restaurante selecionados" do
      get relatorio_global_acessos_path, params: { restaurante: "Restaurante 1", catraca: "Catraca 1" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mariana Souza")
      expect(response.body).not_to include("Carlos Pereira")
    end

    it "exibe mensagem de busca vazia quando não há acessos para o filtro" do
      get relatorio_global_acessos_path, params: { restaurante: "Restaurante 4", catraca: "Catraca 1" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nenhum acesso corresponde à busca")
      expect(response.body).not_to include("Mariana Souza")
    end
  end
end
