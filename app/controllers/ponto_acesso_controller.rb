class PontoAcessoController < ApplicationController
  before_action :exigir_login

  def new
    carregar_restaurantes
  end

  def create
    catraca = Catraca.includes(:restaurante).find_by(id: params[:catraca_id])
    return recusar("Selecione uma catraca") if catraca.nil?

    restaurante = catraca.restaurante
    return recusar("O restaurante #{restaurante.nome} não está disponível") unless restaurante.status_em_operacao?
    return recusar("A catraca #{catraca.numero} não está disponível") if catraca.status_manutencao? || catraca.status_desativada?

    sessao = nil
    # Transação: ou encerra a sessão antiga E abre a nova, ou não faz nada
    SessaoOperacao.transaction do
      # o banco só aceita uma sessão aberta por funcionário
      SessaoOperacao.where(funcionario_id: funcionario_logado.id, encerrada_em: nil)
                    .update_all(encerrada_em: Time.current)
      sessao = SessaoOperacao.create!(
        funcionario: funcionario_logado, catraca: catraca, iniciada_em: Time.current
      )
    end

    session[:sessao_operacao_id] = sessao.id
    redirect_to root_path, notice: "Ponto de acesso: #{restaurante.nome}, catraca #{catraca.numero}"
  rescue ActiveRecord::RecordInvalid => e
    recusar(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    recusar("Essa catraca já está em uso")
  end

  private

  def carregar_restaurantes
    @restaurantes = Restaurante.includes(:catracas).order(:nome)
  end

  # Volta para a mesma tela mostrando o erro (e não cria nenhuma sessão de operação)
  def recusar(mensagem)
    carregar_restaurantes
    flash.now[:alert] = mensagem
    render :new, status: :unprocessable_entity
  end
end
