# Login do funcionário. Esta parte NÃO é obrigatória em todas as páginas: as páginas públicas
# (cadastro/extrato de estudante, cardápio, catraca) continuam abertas. Cada controller que
# precisa de funcionário logado declara: before_action :exigir_login
module Autenticacao
  extend ActiveSupport::Concern

  included do
    helper_method :funcionario_logado, :sessao_operacao_atual
  end

  private

  def funcionario_logado
    return @funcionario_logado if defined?(@funcionario_logado)
    @funcionario_logado = Funcionario.find_by(id: session[:funcionario_id], ativo: true)
  end

  def sessao_operacao_atual
    return @sessao_operacao_atual if defined?(@sessao_operacao_atual)
    @sessao_operacao_atual = SessaoOperacao.find_by(
      id: session[:sessao_operacao_id],
      funcionario_id: funcionario_logado&.id,
      encerrada_em: nil
    )
  end

  def exigir_login
    return if funcionario_logado
    redirect_to login_path, alert: "Faça login para continuar"
  end

  def exigir_administrador
    return if funcionario_logado&.perfil_administrador?
    redirect_to root_path, alert: "Acesso restrito a administradores"
  end

  def exigir_ponto_de_acesso
    return if sessao_operacao_atual
    redirect_to ponto_acesso_path, alert: "Selecione o restaurante e a catraca"
  end
end
