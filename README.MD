# UnB RU

---

Sistema de gerenciamento para o Restaurante Universitário da UnB.

Primeiro de tudo, no terminal do RubyMine, rode: bundle install

Depois prepare o Banco de Dados. Usamos o DataGrip e coloquei tanto user como senha de postgres (default). Depois de instalar tanto o DataGrip como o postgres e criou um novo banco de dados (No DataGrip o caminho é "+">>"Data Source">>"Postgres").

Depois de setado, vá no config/database.yml e coloque seu usuário e senha do Postgres.

Antes de rodar qualquer teste de RSpec ou Cucumber, rode

rails db:test:prepare

Se estiver dando problema de utf-8 na hora de rodar o cucumber, rode todos esses comandos:

Windows:
chcp 65001
$env:RUBYOPT="-Eutf-8"
set RUBYOPT=-Eutf-8
$env:CUCUMBER_OUTPUT_ENCODING="utf-8"

Linux:
export LANG=pt_BR.UTF-8
export RUBYOPT="-Eutf-8"
export CUCUMBER_OUTPUT_ENCODING="utf-8"


Para rodar os testes cucumber e RSpec:

bundle exec rspec
bundle exec cucumber
