# Ajuda a montar o menu de abas do cabeçalho.
module NavegacaoHelper
  # Link do menu. A aba da página em que o usuário está recebe aria-current="page",
  # e o CSS (.abas a[aria-current="page"]) a destaca em azul.
  def link_aba(texto, caminho, nome_icone = nil)
    atual = current_page?(caminho) ? "page" : nil
    link_to caminho, "aria-current": atual do
      safe_join([ (icone(nome_icone) if nome_icone), texto ].compact)
    end
  end
end
