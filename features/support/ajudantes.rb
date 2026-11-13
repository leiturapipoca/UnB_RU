module Ajudantes
  def criar_funcionario(perfil: :operador, siape: "1234567", senha: "senha123")
    Funcionario.create!(siape: siape, nome: "Funcionário Teste", senha: senha, perfil: perfil)
  end

  def entrar_como(funcionario, senha: "senha123")
    visit login_path
    fill_in "SIAPE", with: funcionario.siape
    fill_in "Senha", with: senha
    click_button "Entrar"
  end

  def criar_restaurante_com_catraca(nome: "RU Antigo", campus: nil)
    campus ||= Campus.find_or_create_by!(nome: "Darcy Ribeiro")
    restaurante = Restaurante.create!(campus: campus, nome: nome, piso: 1, capacidade_lugares: 100)
    restaurante.catracas.create!(numero: 1, descricao: "Catraca 1")
    restaurante
  end

  # Cenário completo do FastPass (issue 16). Define @sessao, @estudante, @inscricao, @dia.
  def montar_cenario_fastpass(saldo: 10)
    @dia = Time.zone.local(2026, 11, 11)
    campus = Campus.find_or_create_by!(nome: "Darcy Ribeiro")
    restaurante = criar_restaurante_com_catraca(nome: "RU Darcy", campus: campus)
    @sessao = SessaoOperacao.create!(
      funcionario: criar_funcionario, catraca: restaurante.catracas.first, iniciada_em: Time.current
    )

    turno = Turno.create!(
      campus: campus, tipo_refeicao: :almoco, hora_inicio: "11:00", hora_fim: "14:00",
      fastpass_habilitado: true, tolerancia_atraso_min: 5, antecedencia_min: 5
    )
    janela = JanelaFastpass.create!(turno: turno, hora_inicio: "12:00", hora_fim: "12:15", cota_vagas: 10)

    grupo = GrupoTarifario.create!(nome: "Grupo I")
    Tarifa.create!(grupo_tarifario: grupo, tipo_refeicao: :almoco, valor: 5.00)
    @estudante = Estudante.create!(
      matricula: "242001508", nome: "Aluno Teste", senha_hash: "hash",
      grupo_tarifario: grupo, saldo: saldo
    )

    sorteio = Sorteio.create!(turno: turno, data: @dia.to_date, data_hora_resultado: @dia, status: :realizado)
    @inscricao = InscricaoFastpass.create!(
      sorteio: sorteio, estudante: @estudante, janela_fastpass: janela,
      inscrito_em: @dia, status: :contemplado, codigo_passe: "PASSE123"
    )
  end
end

# "World" só existe dentro do Cucumber; o RSpec carrega este arquivo com require e usa "include Ajudantes"
World(Ajudantes) if respond_to?(:World)
