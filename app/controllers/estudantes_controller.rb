class EstudantesController < ApplicationController
  before_action :require_login, only: [:extrato]

  def new
    @estudante = Estudante.new
  end

  def create
    @estudante = Estudante.new(estudante_params)


    @estudante.grupo_tarifario = GrupoTarifario.first || GrupoTarifario.create!(nome: 'Grupo I')


    if estudante_params.values.any?(&:blank?)
      flash.now[:alert] = "Preencha todos os campos"
      render :new, status: :unprocessable_entity
      return
    end


    unless @estudante.matricula.match?(/\A[0-9]{9}\z/)
      flash.now[:alert] = "A matrícula deve conter exatamente 9 dígitos numéricos"
      render :new, status: :unprocessable_entity
      return
    end


    if @estudante.save
      flash[:notice] = "Usuário cadastrado com sucesso"
      redirect_to new_estudante_path
    else

      if @estudante.errors[:matricula].any?
        flash.now[:alert] = "Estudante já cadastrado"
      end
      render :new, status: :unprocessable_entity
    end
  end

  def extrato
    @estudante = Estudante.find(params[:id])
    @movimentacoes = Extrato.where(estudante_id: @estudante.id).order(data_hora: :desc)

    @total_gasto = @movimentacoes.where(tipo: 'REFEICAO').sum(:valor).abs
    @total_recarregado = @movimentacoes.where(tipo: 'RECARGA').sum(:valor)
    @quantidade_refeicoes = @movimentacoes.where(tipo: 'REFEICAO').count
  end

  private

  def require_login
    unless current_estudante
      flash[:alert] = "Faça login para visualizar seu extrato"
      redirect_to login_path
    end
  end


  def current_estudante
    @current_estudante ||= Estudante.find_by(id: session[:estudante_id]) if session[:estudante_id]
  end


  def estudante_params
    params.require(:estudante).permit(:matricula, :nome, :senha_hash)
  end
end