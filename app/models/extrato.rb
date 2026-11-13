# frozen_string_literal: true

class Extrato < ApplicationRecord
  self.table_name = 'vw_extrato'

  def readonly?
    true
  end
end