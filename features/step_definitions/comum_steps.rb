E(/^exibe uma mensagem de sucesso$/) do
  expect(page).to have_css("#notice")
end
