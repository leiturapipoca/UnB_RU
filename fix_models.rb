# frozen_string_literal: true

models = {
  "campus.rb" => <<~'RUBY',
    class Campus < ApplicationRecord
      self.table_name = "campi"
      has_many :restaurantes, dependent: :restrict_with_error
      has_many :turnos, dependent: :restrict_with_error
      validates :nome, presence: true, uniqueness: true, length: { maximum: 80 }
    end
  RUBY
  "restaurante.rb" => <<~'RUBY',
    class Restaurante < ApplicationRecord
      self.table_name = "restaurantes"
      belongs_to :campus
      has_many :catracas, dependent: :restrict_with_error
      enum :status, { em_operacao: "EM_OPERACAO", indisponivel: "INDISPONIVEL", desativado: "DESATIVADO" }, prefix: :status
      validates :nome, presence: true, length: { maximum: 80 }, uniqueness: { scope: :campus_id }
      validates :piso, numericality: { greater_than_or_equal_to: 1 }
      validates :capacidade_lugares, numericality: { greater_than: 0 }, allow_nil: true
    end
  RUBY
  "catraca.rb" => <<~'RUBY',
    class Catraca < ApplicationRecord
      self.table_name = "catracas"
      belongs_to :restaurante
      has_many :sessoes_operacao, dependent: :restrict_with_error
      enum :modo_operacional, { comum: "COMUM", exclusivo_fastpass: "EXCLUSIVO_FASTPASS" }, prefix: :modo
      enum :status, { online: "ONLINE", offline: "OFFLINE", pronta: "PRONTA", manutencao: "MANUTENCAO", desativada: "DESATIVADA" }, prefix: :status
      validates :numero, numericality: { greater_than: 0 }, uniqueness: { scope: :restaurante_id }
      validates :descricao, length: { maximum: 80 }, allow_nil: true
    end
  RUBY
  "grupo_tarifario.rb" => <<~'RUBY',
    class GrupoTarifario < ApplicationRecord
      self.table_name = "grupos_tarifarios"
      has_many :tarifas, dependent: :destroy
      has_many :estudantes, dependent: :restrict_with_error
      validates :nome, presence: true, uniqueness: true, length: { maximum: 20 }
      validates :descricao, length: { maximum: 200 }, allow_nil: true
    end
  RUBY
  "tarifa.rb" => <<~'RUBY',
    class Tarifa < ApplicationRecord
      self.table_name = "tarifas"
      belongs_to :grupo_tarifario
      enum :tipo_refeicao, { cafe_da_manha: "CAFE_DA_MANHA", almoco: "ALMOCO", jantar: "JANTAR" }, prefix: :tipo
      validates :valor, numericality: { greater_than_or_equal_to: 0 }
      validates :tipo_refeicao, uniqueness: { scope: :grupo_tarifario_id }
    end
  RUBY
  "estudante.rb" => <<~'RUBY',
    class Estudante < ApplicationRecord
      self.table_name = "estudantes"
      belongs_to :grupo_tarifario
      has_many :recargas, dependent: :restrict_with_error
      has_many :inscricoes_fastpass, dependent: :restrict_with_error
      has_many :acessos, dependent: :restrict_with_error
      validates :matricula, presence: true, uniqueness: true, format: { with: /\A[0-9]{9}\z/ }
      validates :nome, presence: true, length: { maximum: 120 }
      validates :senha_hash, presence: true, length: { maximum: 255 }
      validates :saldo, numericality: true
      validates :notificacoes_ativas, inclusion: { in: [true, false] }
    end
  RUBY
  "funcionario.rb" => <<~'RUBY',
    class Funcionario < ApplicationRecord
      self.table_name = "funcionarios"
      has_many :sessoes_operacao, dependent: :restrict_with_error
      enum :perfil, { operador: "OPERADOR", gestor: "GESTOR", administrador: "ADMINISTRADOR" }, prefix: :perfil
      validates :siape, presence: true, uniqueness: true, format: { with: /\A[0-9]{7}\z/ }
      validates :nome, presence: true, length: { maximum: 120 }
      validates :senha_hash, presence: true, length: { maximum: 255 }
      validates :ativo, inclusion: { in: [true, false] }
    end
  RUBY
  "recarga.rb" => <<~'RUBY',
    class Recarga < ApplicationRecord
      self.table_name = "recargas"
      belongs_to :estudante
      enum :metodo_pagamento, { pix: "PIX", cartao_credito: "CARTAO_CREDITO" }, prefix: :metodo
      enum :status, { pendente: "PENDENTE", confirmada: "CONFIRMADA", falhou: "FALHOU", expirada: "EXPIRADA" }, prefix: :status
      validates :valor, numericality: { greater_than: 0 }
      validates :codigo_transacao, uniqueness: true, allow_nil: true, length: { maximum: 64 }
      validates :solicitada_em, presence: true
      validate :consistencia_status_confirmacao

      private
      def consistencia_status_confirmacao
        if (status == "confirmada" && confirmada_em.nil?) || (status != "confirmada" && !confirmada_em.nil?)
          errors.add(:confirmada_em, "deve estar preenchida se, e somente se, o status for CONFIRMADA")
        end
      end
    end
  RUBY
  "turno.rb" => <<~'RUBY',
    class Turno < ApplicationRecord
      self.table_name = "turnos"
      belongs_to :campus
      has_many :janelas_fastpass, dependent: :destroy
      has_many :cardapios, dependent: :destroy
      has_many :sorteios, dependent: :destroy
      has_many :acessos, dependent: :restrict_with_error
      enum :tipo_refeicao, { cafe_da_manha: "CAFE_DA_MANHA", almoco: "ALMOCO", jantar: "JANTAR" }, prefix: :tipo
      validates :tipo_refeicao, uniqueness: { scope: :campus_id }
      validates :tolerancia_atraso_min, numericality: { greater_than_or_equal_to: 0 }
      validates :antecedencia_min, numericality: { greater_than_or_equal_to: 0 }
      validates :ativo, :fastpass_habilitado, :trava_pontualidade, inclusion: { in: [true, false] }
      validates :hora_inicio, :hora_fim, presence: true
      validate :hora_inicio_menor_que_hora_fim

      private
      def hora_inicio_menor_que_hora_fim
        if hora_inicio.present? && hora_fim.present? && hora_inicio >= hora_fim
          errors.add(:hora_inicio, "deve ser anterior à hora_fim")
        end
      end
    end
  RUBY
  "janela_fastpass.rb" => <<~'RUBY',
    class JanelaFastpass < ApplicationRecord
      self.table_name = "janelas_fastpass"
      belongs_to :turno
      has_many :inscricoes_fastpass, dependent: :restrict_with_error
      validates :hora_inicio, uniqueness: { scope: :turno_id }, presence: true
      validates :hora_fim, presence: true
      validates :cota_vagas, numericality: { greater_than_or_equal_to: 0 }
      validates :ativa, inclusion: { in: [true, false] }
      validate :hora_inicio_menor_que_hora_fim

      private
      def hora_inicio_menor_que_hora_fim
        if hora_inicio.present? && hora_fim.present? && hora_inicio >= hora_fim
          errors.add(:hora_inicio, "deve ser anterior à hora fim")
        end
      end
    end
  RUBY
  "cardapio.rb" => <<~'RUBY',
    class Cardapio < ApplicationRecord
      self.table_name = "cardapios"
      belongs_to :turno
      has_many :itens_cardapio, dependent: :destroy
      validates :data, uniqueness: { scope: :turno_id }, presence: true
    end
  RUBY
  "item_cardapio.rb" => <<~'RUBY',
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
  RUBY
  "sorteio.rb" => <<~'RUBY',
    class Sorteio < ApplicationRecord
      self.table_name = "sorteios"
      belongs_to :turno
      has_many :inscricoes_fastpass, dependent: :restrict_with_error
      enum :status, { inscricoes_abertas: "INSCRICOES_ABERTAS", realizado: "REALIZADO", cancelado: "CANCELADO" }, prefix: :status
      validates :data, uniqueness: { scope: :turno_id }, presence: true
      validates :data_hora_resultado, presence: true
    end
  RUBY
  "inscricao_fastpass.rb" => <<~'RUBY',
    class InscricaoFastpass < ApplicationRecord
      self.table_name = "inscricoes_fastpass"
      belongs_to :sorteio
      belongs_to :estudante
      belongs_to :janela_fastpass
      has_many :acessos, dependent: :restrict_with_error
      enum :status, {
        aguardando_sorteio: "AGUARDANDO_SORTEIO", contemplado: "CONTEMPLADO",
        nao_contemplado: "NAO_CONTEMPLADO", vaga_liberada: "VAGA_LIBERADA",
        utilizada: "UTILIZADA", expirada: "EXPIRADA"
      }, prefix: :status
      validates :estudante_id, uniqueness: { scope: :sorteio_id }
      validates :codigo_passe, uniqueness: true, allow_nil: true, length: { maximum: 20 }
      validates :inscrito_em, presence: true
      validate :validade_codigo_passe

      private
      def validade_codigo_passe
        status_validos = %w[contemplado vaga_liberada utilizada expirada]
        if codigo_passe.present? && !status_validos.include?(status)
          errors.add(:codigo_passe, "só pode existir para os status de contemplação/uso")
        end
      end
    end
  RUBY
  "sessao_operacao.rb" => <<~'RUBY',
    class SessaoOperacao < ApplicationRecord
      self.table_name = "sessoes_operacao"
      belongs_to :funcionario
      belongs_to :catraca
      has_many :acessos, dependent: :restrict_with_error
      validates :iniciada_em, presence: true
      validates :catraca_id, uniqueness: { conditions: -> { where(encerrada_em: nil) }, message: "já possui uma sessão aberta" }
      validates :funcionario_id, uniqueness: { conditions: -> { where(encerrada_em: nil) }, message: "já possui uma sessão aberta" }
      validate :encerrada_em_valida

      private
      def encerrada_em_valida
        if encerrada_em.present? && iniciada_em.present? && encerrada_em <= iniciada_em
          errors.add(:encerrada_em, "deve ser posterior ao início da sessão")
        end
      end
    end
  RUBY
  "acesso.rb" => <<~'RUBY',
    class Acesso < ApplicationRecord
      self.table_name = "acessos"
      belongs_to :sessao_operacao
      belongs_to :turno, optional: true
      belongs_to :estudante, optional: true
      belongs_to :inscricao_fastpass, optional: true
      enum :modalidade, { comum: "COMUM", fastpass: "FASTPASS" }, prefix: :modalidade
      enum :resultado, { liberado: "LIBERADO", bloqueado: "BLOQUEADO" }, prefix: :resultado
      enum :motivo_bloqueio, {
        identificacao_invalida: "IDENTIFICACAO_INVALIDA", saldo_insuficiente: "SALDO_INSUFICIENTE",
        entrada_ja_registrada: "ENTRADA_JA_REGISTRADA", fora_do_turno: "FORA_DO_TURNO",
        fora_da_janela: "FORA_DA_JANELA", sem_fastpass: "SEM_FASTPASS",
        validacao_offline_indisponivel: "VALIDACAO_OFFLINE_INDISPONIVEL"
      }, prefix: :motivo
      enum :divergencia, { entrada_duplicada: "ENTRADA_DUPLICADA", saldo_negativo: "SALDO_NEGATIVO" }, prefix: :divergencia
      validates :valor_cobrado, numericality: { greater_than_or_equal_to: 0 }
      validates :identificacao_lida, presence: true, length: { maximum: 64 }
      validates :data_hora, presence: true
      validate :sincronizacao_valida

      private
      def sincronizacao_valida
        if sincronizado_em.present? && data_hora.present? && sincronizado_em < data_hora
          errors.add(:sincronizado_em, "não pode ser anterior à data/hora original do acesso")
        end
      end
    end
  RUBY
}

models.each do |file, content|
  File.write(File.join("app", "models", file), content)
  puts "Atualizado: app/models/#{file}"
end