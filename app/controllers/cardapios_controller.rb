# frozen_string_literal: true

class CardapiosController < ApplicationController
  def atual
    @cardapio = Cardapio.refeicao_atual(hora_referencia_cardapio)

    if @cardapio.nil?
      flash.now[:notice] = "Nenhuma refeição está sendo servida no momento"
    else
      @itens = @cardapio.itens_cardapio.order(:ordem)
    end
  end

  private

  def hora_referencia_cardapio
    return Time.current unless Rails.env.development? && params[:hora].present?

    hora, minuto = params[:hora].split(":").map(&:to_i)
    Time.current.change(hour: hora, min: minuto, sec: 0)
  rescue ArgumentError
    Time.current
  end
end
