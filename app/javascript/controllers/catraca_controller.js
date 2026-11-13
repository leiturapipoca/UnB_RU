import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "identificacao", "mensagem" ]

  connect() {
    this.onlineHandler = () => this.sincronizarDados()
    window.addEventListener('online', this.onlineHandler)
  }

  disconnect() {
    window.removeEventListener('online', this.onlineHandler)
  }

  validar(event) {
    if (!navigator.onLine) {
      event.preventDefault()
      this.registrarOffline()
    }
  }

  registrarOffline() {
    const matricula = this.identificacaoTarget.value.trim()
    
    if (matricula === "") {
      this.exibirMensagem("Validação indisponível offline", "red")
      return
    }

    let acessos = JSON.parse(localStorage.getItem('acessos_offline')) || []
    acessos.push(matricula)
    localStorage.setItem('acessos_offline', JSON.stringify(acessos))

    this.exibirMensagem("Catraca Liberada", "orange")
    this.identificacaoTarget.value = ""
  }

  sincronizarDados() {
    let acessos = JSON.parse(localStorage.getItem('acessos_offline')) || []
    if (acessos.length === 0) return

    // Pega o token CSRF gerado pelo Rails na página
    const metaToken = document.querySelector('meta[name="csrf-token"]')
    const token = metaToken ? metaToken.content : ''

    fetch('/catraca/sincronizar', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token
      },
      body: JSON.stringify({ acessos: acessos })
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'sucesso') {
        localStorage.removeItem('acessos_offline')
        this.exibirMensagem(`Sincronizado com sucesso: ${data.sincronizados} acessos`, "green")
      }
    })
    .catch(error => {
      console.error('Erro na sincronização:', error)
    })
  }

  exibirMensagem(texto, cor) {
    const classeCss = cor === "red" ? "status-bloqueada" : "status-liberada"
    this.mensagemTarget.innerHTML = `<div class="${classeCss}" style="color: ${cor}; font-weight: bold; margin-bottom: 20px;">${texto}</div>`
  }
}