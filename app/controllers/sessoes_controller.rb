class SessoesController < ApplicationController
  # Só o logout exige estar logado; a tela de login e o envio do formulário são públicos
  before_action :exigir_login, only: :destroy

  # Tela de login do funcionário. Também é o destino para onde as páginas do estudante
  # redirecionam quem não está logado (a mensagem vem em flash[:alert]).
  def new
    redirect_to root_path if funcionario_logado
  end

  def create
    funcionario = Funcionario.autenticar(params[:siape], params[:senha])

    if funcionario
      reset_session # evita fixação de sessão
      session[:funcionario_id] = funcionario.id
      # Logo após o login o funcionário escolhe em qual restaurante/catraca vai operar (issue 5)
      redirect_to ponto_acesso_path
    else
      flash.now[:alert] = "SIAPE ou senha inválidos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sessao_operacao_atual&.update(encerrada_em: Time.current)
    reset_session
    redirect_to login_path, notice: "Você saiu do sistema"
  end

  # Atalho usado nos testes do extrato do estudante (rota só existe em test/development)
  def test_login
    session[:estudante_id] = params[:id]
    redirect_to extrato_estudante_path(params[:id])
  end
end
