class PainelController < ApplicationController
  before_action :exigir_login
  # A tela principal só abre depois de escolher restaurante e catraca
  before_action :exigir_ponto_de_acesso

  def index
  end
end
