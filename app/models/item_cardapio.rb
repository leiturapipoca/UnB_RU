class ItemCardapio < ApplicationRecord
  self.table_name = "itens_cardapio"
  belongs_to :cardapio
  enum :categoria, {
    bebida: "BEBIDA", panificacao: "PANIFICACAO", opcao_extra: "OPCAO_EXTRA",
    gordura: "GORDURA", complemento: "COMPLEMENTO", fruta: "FRUTA",
    salada: "SALADA", molho_salada: "MOLHO_SALADA", prato_principal: "PRATO_PRINCIPAL",
    guarnicao: "GUARNICAO", acompanhamento: "ACOMPANHAMENTO", sopa: "SOPA",
    torrada: "TORRADA", sobremesa: "SOBREMESA"
  }, prefix: :categoria
  enum :opcao, { geral: "GERAL", padrao: "PADRAO", ovolactovegetariano: "OVOLACTOVEGETARIANO", vegetariano_estrito: "VEGETARIANO_ESTRITO" }, prefix: :opcao
  validates :descricao, presence: true, length: { maximum: 160 }
  validates :ordem, presence: true, numericality: { only_integer: true }
end
