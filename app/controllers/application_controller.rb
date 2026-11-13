class ApplicationController < ActionController::Base
  # Traz para todos os controllers: exigir_login, funcionario_logado, etc.
  include Autenticacao

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
