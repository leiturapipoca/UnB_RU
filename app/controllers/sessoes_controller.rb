class SessoesController < ApplicationController
  skip_before_action :exigir_login, only: %i[new create]

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
end
