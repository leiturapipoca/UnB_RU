# Steps da feature features/validacaoRigorosa.feature
# montar_cenario_fastpass (features/support/ajudantes.rb) cria turno, janela 12:00–12:15, tarifa de R$ 5,
# estudante com saldo e a inscrição contemplada com o código "PASSE123".

Dado(/^que o aluno foi sorteado para o Fastpass$/) do
  montar_cenario_fastpass(saldo: 10)
end

Dado(/^que o aluno chega no horário vigente$/) do
  travel_to @dia.change(hour: 12, min: 5) # dentro da janela 12:00–12:15
end

Dado(/^que o aluno chega atrasado$/) do
  travel_to @dia.change(hour: 12, min: 40) # passou de 12:15 + 5 min de tolerância
end

Quando(/^o sistema verifica a chegada do aluno$/) do
  @resultado = ValidadorFastpass.new(sessao_operacao: @sessao, codigo_passe: "PASSE123").validar
end

Então(/^o sistema libera a catraca física$/) do
  expect(@resultado).to be_liberado
  expect(@resultado.acesso).to be_resultado_liberado
end

E(/^debita o saldo do aluno$/) do
  expect(@estudante.reload.saldo).to eq(5) # 10 − tarifa de 5
end

Então(/^o sistema bloqueia a entrada do aluno$/) do
  expect(@resultado).not_to be_liberado
  expect(@resultado.motivo).to eq(:fora_da_janela)
  expect(@estudante.reload.saldo).to eq(10) # nada foi cobrado
end
