# frozen_string_literal: true

class SessoesController < ApplicationController
  def new

    render inline: "<%= flash[:alert] %>"
  end


  def test_login
    session[:estudante_id] = params[:id]
    redirect_to extrato_estudante_path(params[:id])
  end
end