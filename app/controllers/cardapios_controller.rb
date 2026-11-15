# frozen_string_literal: true

class CardapiosController < ApplicationController
  # action
  def atual
    # chama o metodo refeicao_atual da model e fornece como variavel de instancia
    # pra view com o @
    @cardapio = Cardapio.refeicao_atual

    if @cardapio.nil?
      # flash solta uma mensagem de aviso pro usuario
      flash.now[:notice] = "Nenhuma refeição está sendo servida no momento"
    else
      # includes para evitar queries N+1 ao renderizar os itens, possivelmente
      # removivel
      @itens = @cardapio.itens_cardapio.order(:ordem)
    end
  end
end
