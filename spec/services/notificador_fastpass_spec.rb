# frozen_string_literal: true

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificadorFastpass, type: :service do
  let(:grupo) { GrupoTarifario.create!(nome: 'Padrão') }
  let(:estudante) { Estudante.create!(matricula: '242001508', nome: 'Guilherme', senha_hash: '123', grupo_tarifario: grupo, notificacoes_ativas: true) }
  let(:campus) { Campus.create!(nome: 'Campus Darcy Ribeiro') }
  let(:turno) { Turno.create!(campus: campus, tipo_refeicao: 'ALMOCO', hora_inicio: '12:00', hora_fim: '14:30') }
  let(:sorteio) { Sorteio.create!(turno: turno, data: Date.current, data_hora_resultado: Time.current) }
  let(:janela) { JanelaFastpass.create!(turno: turno, hora_inicio: '12:00', hora_fim: '12:15', cota_vagas: 10) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  describe '.processar' do
    context 'quando o estudante foi contemplado' do
      let!(:inscricao) do
        InscricaoFastpass.create!(
          estudante: estudante, sorteio: sorteio, janela_fastpass: janela,
          status: 'CONTEMPLADO', codigo_passe: 'PASSE123',
          inscrito_em: Time.current
        )
      end

      it 'envia o e-mail de notificação e atualiza o status' do
        expect {
          described_class.processar(sorteio)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        inscricao.reload
        expect(inscricao.notificado_em).not_to be_nil

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to include("Você ganhou o sorteio")
      end

      it 'não envia e-mail se as notificações estiverem desativadas, mas carimba o horário' do
        estudante.update!(notificacoes_ativas: false)

        expect {
          described_class.processar(sorteio)
        }.not_to change { ActionMailer::Base.deliveries.count }

        inscricao.reload
        expect(inscricao.notificado_em).not_to be_nil
      end

      it 'não reenvia notificação se já foi notificado anteriormente' do
        inscricao.update!(notificado_em: 1.hour.ago)

        expect {
          described_class.processar(sorteio)
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'quando o estudante não foi contemplado' do
      let!(:inscricao_perdedor) do
        InscricaoFastpass.create!(
          estudante: estudante, sorteio: sorteio, janela_fastpass: janela,
          status: 'NAO_CONTEMPLADO',
          inscrito_em: Time.current
        )
      end

      it 'envia e-mail com a mensagem de não contemplado' do
        described_class.processar(sorteio)

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to include("Você não ganhou o sorteio")
        expect(inscricao_perdedor.reload.notificado_em).not_to be_nil
      end
    end
  end
end
