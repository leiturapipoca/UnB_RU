class RestaurantesController < ApplicationController
  # Só o administrador cadastra/edita/remove restaurantes (a ordem importa: primeiro o login)
  before_action :exigir_login
  before_action :exigir_administrador
  before_action :carregar_restaurante, only: %i[edit update destroy]

  def index
    @restaurantes = Restaurante.includes(:campus, :catracas).order(:nome)
  end

  def new
    @restaurante = Restaurante.new
    @restaurante.catracas.build # uma linha de catraca em branco no formulário
  end

  def create
    @restaurante = Restaurante.new(restaurante_params)
    if @restaurante.save
      redirect_to restaurantes_path, notice: "Restaurante cadastrado com sucesso"
    else
      @restaurante.catracas.build if @restaurante.catracas.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @restaurante.update(restaurante_params)
      redirect_to restaurantes_path, notice: "Restaurante atualizado com sucesso"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @restaurante.destroy!
    redirect_to restaurantes_path, notice: "Restaurante removido com sucesso"
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
    redirect_to restaurantes_path,
      alert: "Não é possível remover: há sessões de operação registradas. Desative o restaurante."
  end

  private

  def carregar_restaurante
    @restaurante = Restaurante.find(params[:id])
  end

  # Segurança (strong parameters): só aceita os campos listados
  def restaurante_params
    params.require(:restaurante).permit(
      :campus_id, :nome, :piso, :capacidade_lugares, :status,
      catracas_attributes: %i[id numero descricao modo_operacional status _destroy]
    )
  end
end
