class FastpassMailer < ApplicationMailer
  def resultado_sorteio(inscricao)
    @estudante = inscricao.estudante
    @inscricao = inscricao
    @ganhou = inscricao.status_contemplado?
    @mensagem_resultado = @ganhou ? "Você ganhou o sorteio" : "Você não ganhou o sorteio"
    mail(
      to: "#{@estudante.matricula.strip}@aluno.unb.br",
      subject: "Resultado do Sorteio FastPass RU: #{@mensagem_resultado}"
    ) do |format|
      format.text { render plain: "#{@mensagem_resultado}. Código: #{@inscricao.codigo_passe}" }
    end
  end
end