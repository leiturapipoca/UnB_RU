ENV['CUCUMBER_OUTPUT_ENCODING'] = 'utf-8'

# --- Início da correção para o Ruby 3.2+ ---
class File
  def self.exists?(*args)
    exist?(*args)
  end
end

class Dir
  def self.exists?(*args)
    exist?(*args)
  end
end
# --- Fim da correção ---
module Kernel
  alias_method :original_backtick, :`
  def `(command)
    if command.to_s.include?("chcp")
      begin
        original_backtick(command)
      rescue ArgumentError
        "Página de código ativa: 65001" # Retorna um fallback seguro caso o encoding falhe
      end
    else
      original_backtick(command)
    end
  end
end
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup" # Set up gems listed in the Gemfile.
ENV['CUCUMBER_OUTPUT_ENCODING'] = 'utf-8'
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
