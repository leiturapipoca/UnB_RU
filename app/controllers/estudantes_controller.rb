class EstudantesController < ApplicationController
  def new
    @estudante = Estudante.new
  end

  def create
    @estudante = Estudante.new(estudante_params)

    # Associa um grupo padrão para passar na validação do banco (já que o form não envia isso)
    @estudante.grupo_tarifario = GrupoTarifario.first || GrupoTarifario.create!(nome: 'Grupo I')

    # Regra do Cenário: Campos vazios
    if estudante_params.values.any?(&:blank?)
      flash.now[:alert] = "Preencha todos os campos"
      render :new, status: :unprocessable_entity
      return
    end

    # Regra do Cenário: Matrícula inválida
    unless @estudante.matricula.match?(/\A[0-9]{9}\z/)
      flash.now[:alert] = "A matrícula deve conter exatamente 9 dígitos numéricos"
      render :new, status: :unprocessable_entity
      return
    end

    # Tenta salvar no banco de dados
    if @estudante.save
      # Sucesso: redireciona e mostra notice[cite: 608]
      flash[:notice] = "Usuário cadastrado com sucesso"
      redirect_to new_estudante_path
    else
      # Regra do Cenário: Matrícula já registrada (Uniqueness do Active Record)
      if @estudante.errors[:matricula].any?
        flash.now[:alert] = "Estudante já cadastrado"
      end
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Segurança: permite apenas os campos específicos do form
  def estudante_params
    params.require(:estudante).permit(:matricula, :nome, :senha_hash)
  end
end