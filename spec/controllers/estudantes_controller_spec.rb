RSpec.describe "Histórico e Exportação em PDF", type: :request do
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
  let!(:restaurante) { Restaurante.find_or_create_by!(campus: campus, nome: "Restaurante 1") { |r| r.piso = 1 } }
  let!(:catraca) do
    Catraca.find_or_create_by!(restaurante: restaurante, numero: 1) { |c| c.descricao = "Catraca 1" }
  end
  let!(:funcionario) do
    Funcionario.find_or_create_by!(siape: "1000003") do |f|
      f.nome = "Operador Extrato"
      f.senha_hash = "hash"
      f.perfil = :operador
      f.ativo = true
    end
  end
  let!(:sessao) do
    SessaoOperacao.find_by(catraca: catraca, encerrada_em: nil) ||
      SessaoOperacao.create!(catraca: catraca, funcionario: funcionario, iniciada_em: Time.current)
  end

  let!(:estudante_com_refeicao) do
    Estudante.find_or_create_by!(matricula: "242001508") do |e|
      e.nome = "Guilherme Silva Cavalcante"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
    end
  end

  let!(:estudante_sem_refeicao) do
    Estudante.find_or_create_by!(matricula: "242009999") do |e|
      e.nome = "Estudante Sem Refeicoes"
      e.senha_hash = "hash"
      e.grupo_tarifario = grupo
    end
  end

  before do
    unless Acesso.exists?(estudante: estudante_com_refeicao, turno: turno)
      Acesso.create!(
        sessao_operacao: sessao,
        turno: turno,
        estudante: estudante_com_refeicao,
        identificacao_lida: estudante_com_refeicao.matricula.strip,
        data_hora: Time.current,
        modalidade: :comum,
        resultado: :liberado,
        valor_cobrado: 0.0
      )
    end
  end

  it "gera e faz o download do PDF extrato_refeicoes.pdf quando há refeições" do
    get test_login_path(estudante_com_refeicao.id)
    post exportar_historico_refeicoes_path, params: { formato: "PDF" }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Type"]).to include("application/pdf")
    expect(response.headers["Content-Disposition"]).to include('filename="extrato_refeicoes.pdf"')
    expect(response.body).to start_with("%PDF-1.4")
  end

  it "bloqueia a geração do PDF e informa mensagem quando não há refeições" do
    get test_login_path(estudante_sem_refeicao.id)
    post exportar_historico_refeicoes_path, params: { formato: "PDF" }

    expect(response).to redirect_to(historico_refeicoes_path)
    expect(response.headers["Content-Type"]).not_to include("application/pdf")
    expect(flash[:alert]).to eq("Nenhum registro no histórico")
  end
end
