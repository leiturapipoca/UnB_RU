require 'rails_helper'

RSpec.describe CardapiosController, type: :controller do
  describe 'GET #atual' do
    let(:fake_cardapio) { instance_double('Cardapio') }

    it 'chama o método do model que busca a refeição pelo horário' do
      expect(Cardapio).to receive(:refeicao_atual)
      get :atual
    end

    context 'quando o RU está no horário de funcionamento' do
      before do
        allow(Cardapio).to receive(:refeicao_atual).and_return(fake_cardapio)


        fake_relation = double('ActiveRecord::Relation')


        allow(fake_cardapio).to receive(:itens_cardapio).and_return(fake_relation)


        allow(fake_relation).to receive(:order).with(:ordem).and_return([])
      end

      it 'seleciona o template atual para renderização' do
        get :atual
        expect(response).to render_template('atual')
      end

      it 'disponibiliza os resultados do cardápio para o template' do
        get :atual
        expect(assigns(:cardapio)).to eq(fake_cardapio)
      end
    end

    context 'quando o RU está fora do horário de funcionamento' do
      before do
        allow(Cardapio).to receive(:refeicao_atual).and_return(nil)
        get :atual
      end

      it 'define a mensagem de flash correta' do
        expect(flash.now[:notice]).to eq("Nenhuma refeição está sendo servida no momento")
      end
    end
  end
end
