# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EstudantesController, type: :controller do
  let(:grupo) { GrupoTarifario.find_or_create_by!(nome: 'Grupo I') }

  describe 'GET #new' do
    it 'instancia um novo estudante e renderiza o template new' do
      get :new
      expect(assigns(:estudante)).to be_a_new(Estudante)
      expect(response).to render_template('new')
    end
  end

  describe 'POST #create' do
    context 'com parâmetros válidos' do
      let(:valid_params) do
        { estudante: { matricula: '123456789', nome: 'Fulano', senha_hash: 'secret' } }
      end

      before { grupo } # garante a existência do grupo

      it 'cria um novo estudante e redireciona' do
        expect {
          post :create, params: valid_params
        }.to change(Estudante, :count).by(1)

        expect(flash[:notice]).to eq("Usuário cadastrado com sucesso")
        expect(response).to redirect_to(new_estudante_path)
      end
    end

    context 'com campos em branco' do
      let(:blank_params) do
        { estudante: { matricula: '', nome: '', senha_hash: '' } }
      end

      it 'não cria estudante e mostra erro' do
        expect {
          post :create, params: blank_params
        }.not_to change(Estudante, :count)

        expect(flash.now[:alert]).to eq("Preencha todos os campos")
        expect(response).to render_template('new')
      end
    end
    context 'com matrícula já registrada' do
      let(:duplicated_params) do
        { estudante: { matricula: '123456789', nome: 'Outro Aluno', senha_hash: 'senha321' } }
      end

      before do
        grupo
        Estudante.create!(matricula: '123456789', nome: 'Aluno Original', senha_hash: 'senha123', grupo_tarifario: grupo, saldo: 0)
      end

      it 'não cria um novo estudante e exibe alerta de duplicidade' do
        expect {
          post :create, params: duplicated_params
        }.not_to change(Estudante, :count)

        expect(flash.now[:alert]).to eq("Estudante já cadastrado")
        expect(response).to render_template('new')
      end
    end

    context 'com matrícula inválida (fora do formato 9 dígitos)' do
      let(:invalid_format_params) do
        { estudante: { matricula: '123', nome: 'Aluno', senha_hash: 'senha123' } }
      end

      before { grupo }

      it 'não cria estudante e alerta sobre a regra de preenchimento' do
        expect {
          post :create, params: invalid_format_params
        }.not_to change(Estudante, :count)

        expect(flash.now[:alert]).to eq("A matrícula deve conter exatamente 9 dígitos numéricos")
        expect(response).to render_template('new')
      end
    end
  end

  describe 'GET #extrato' do
    let(:grupo) { GrupoTarifario.find_or_create_by!(nome: 'Grupo Teste') }
    let(:estudante) { Estudante.create!(matricula: '123456789', nome: 'Guilherme', senha_hash: '123', grupo_tarifario: grupo, saldo: 0.0) }

    context 'quando o usuário não está logado' do
      it 'redireciona para a página de login com alerta' do
        get :extrato, params: { id: estudante.id }
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq('Faça login para visualizar seu extrato')
      end
    end

    context 'quando o usuário está logado' do
      before do

        allow(controller).to receive(:current_estudante).and_return(estudante)
      end

      it 'renderiza o template de extrato com sucesso' do
        get :extrato, params: { id: estudante.id }
        expect(response).to render_template(:extrato) #[cite: 194]
        expect(assigns(:estudante)).to eq(estudante)
      end

      it 'carrega o extrato com valores iniciais zerados se não há histórico' do
        get :extrato, params: { id: estudante.id }
        expect(assigns(:movimentacoes)).to be_empty
        expect(assigns(:total_recarregado)).to eq(0)
      end

      it 'calcula corretamente o total recarregado quando há recargas confirmadas no banco' do
        Recarga.create!(estudante: estudante, valor: 100.0, metodo_pagamento: 'PIX', status: 'CONFIRMADA', solicitada_em: Time.current, confirmada_em: Time.current)

        get :extrato, params: { id: estudante.id }
        expect(assigns(:total_recarregado)).to eq(100.0)
      end
    end
  end
end