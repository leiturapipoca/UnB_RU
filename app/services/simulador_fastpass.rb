# frozen_string_literal: true

require "securerandom"

class SimuladorFastpass
  Resultado = Struct.new(:sucesso, :sorteios_processados, :contemplados, :nao_contemplados, :erro, keyword_init: true) do
    def sucesso? = sucesso
  end

  def executar
    sorteios_alvo = Sorteio.status_inscricoes_abertas
                           .joins(:inscricoes_fastpass)
                           .where(inscricoes_fastpass: { status: "AGUARDANDO_SORTEIO" })
                           .distinct

    if sorteios_alvo.empty?
      return Resultado.new(sucesso: false, erro: "Nenhuma inscrição aguardando sorteio no momento.")
    end

    total_contemplados = 0
    total_nao_contemplados = 0
    processados = []

    sorteios_alvo.each do |sorteio|
      ActiveRecord::Base.transaction do
        inscricoes_por_janela = sorteio.inscricoes_fastpass
                                       .status_aguardando_sorteio
                                       .includes(:janela_fastpass)
                                       .group_by(&:janela_fastpass)

        inscricoes_por_janela.each do |janela, inscricoes|
          vagas = janela.cota_vagas.to_i
          embaralhadas = inscricoes.shuffle

          embaralhadas.first(vagas).each do |inscricao|
            inscricao.update!(status: :contemplado, codigo_passe: gerar_codigo_passe)
            total_contemplados += 1
          end

          embaralhadas.drop(vagas).each do |inscricao|
            inscricao.update!(status: :nao_contemplado, codigo_passe: nil)
            total_nao_contemplados += 1
          end
        end

        sorteio.update!(status: :realizado)
      end

      NotificadorFastpass.processar(sorteio)
      processados << sorteio
    end

    Resultado.new(
      sucesso: true,
      sorteios_processados: processados.size,
      contemplados: total_contemplados,
      nao_contemplados: total_nao_contemplados
    )
  end

  private

  def gerar_codigo_passe
    loop do
      codigo = "FP-#{SecureRandom.alphanumeric(6).upcase}"
      break codigo unless InscricaoFastpass.exists?(codigo_passe: codigo)
    end
  end
end
