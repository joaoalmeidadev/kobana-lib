# 🧭 Kobana Ruby Client

Cliente Ruby para integração com a **API de Pagamentos Kobana (PIX)**.  
Este client fornece serviços para **criação de contas PIX** e **geração de cobranças PIX**, com validação, tradução de payloads e tratamento de erros.

---

## 📦 Sumário
1. [Instalação](#instalação)  
2. [Configuração](#configuração)  
   - [Variáveis de Ambiente](#variáveis-de-ambiente)  
   - [Configuração Global](#configuração-global)  
3. [Uso](#uso)  
   - [Criar Conta PIX](#criar-conta-pix)  
   - [Criar Cobrança PIX](#criar-cobrança-pix)  
4. [Arquitetura Interna](#arquitetura-interna)  
5. [Erros e Exceções](#erros-e-exceções)

---

## ⚙️ Instalação

Clone o repositório e instale as dependências:

```bash
bundle install
```

---

## 🧩 Configuração

### Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```bash
KOBANA_API_KEY=seu_token_aqui
KOBANA_ENV=development  # ou 'production'
```

### Configuração Global

```ruby
require_relative 'kobana'

Kobana.configure do |config|
  config.api_key = ENV['KOBANA_API_KEY']
  config.environment = 'development' # ou 'production'
end
```

---

## 🚀 Uso

Para testar interativamente:

```bash
bundle exec irb -r ./kobana.rb
```

---

### 🏦 Criar Conta PIX

#### Exemplo de Payload

```ruby
payload = {
  custom_name: "Conta principal",
  financial_provider_slug: "example_bank",
  key: "keyexample@email.com",
  enabled: true,
  default: true
}
```

#### Exemplo de Uso

```ruby
begin
  service = Kobana::CreatePixAccountService.new(
    data: payload,
    which_endpoint: :create_pix_account,
    api_key: {SUA_API_KEY}
  )

  response = service.call

  puts "✅ Conta PIX criada com sucesso!"
  puts "UID: #{response['uid']}"
  puts "ID: #{response['id']}"
rescue Kobana::Errors::ValidationError => e
  puts "❌ Erro de validação: #{e.message}"
rescue Kobana::Errors::UnauthorizedError => e
  puts "❌ Não autorizado: #{e.message}"
rescue Kobana::Errors::ApiError => e
  puts "❌ Erro da API (#{e.code}): #{e.message}"
end
```

---

### Criar Cobrança PIX

#### Exemplo de Payload

```ruby
payload = {
  amount: 100.50,
  payer: {
    document_number: '12345678909',
    name: 'João da Silva',
    email: 'joao@email.com'
  },
  pix_account_uid: '{UID_RETORNADO_DO_ENDPOINT_DE_CRIAR_CONTA_PIX}',
  expire_at: (Time.now + 86400).iso8601, # expira em 24h
  external_id: 'pedido_001'
}
```

#### Exemplo de Uso

```ruby
begin
  service = Kobana::ChargePixService.new(
    data: payload,
    which_endpoint: :charge_pix,
    api_key: {SUA_API_KEY}
  )

  response = service.call

  puts "✅ Cobrança criada com sucesso!"
  puts "ID: #{response['id']}"
  puts "UID: #{response['uid']}"
  puts "QR Code: #{response['url']}"
  puts "Payload PIX: #{response['payload']}"
rescue Kobana::Errors::ValidationError => e
  puts "❌ Erro de validação: #{e.message}"
rescue => e
  puts "❌ Erro inesperado: #{e.message}"
end
```

---

## 🧱 Arquitetura Interna

O client segue uma arquitetura modular, separando responsabilidades:

| Componente | Responsabilidade |
|-------------|------------------|
| **Base** | Define configuração comum, headers, autenticação e lógica de requisições HTTP. |
| **Service** | Implementa operações específicas (ex: `CreatePixAccountService`, `ChargePixService`). |
| **Translator** | Monta o payload enviado à API a partir dos dados fornecidos. |
| **Validator** | Valida os dados antes do envio, garantindo integridade e formato. |
| **Errors** | Define erros customizados para respostas HTTP (ex: `ValidationError`, `UnauthorizedError`, `ApiError`). |

---

## ⚠️ Erros e Exceções

| Erro | Quando ocorre |
|------|----------------|
| `Kobana::Errors::ValidationError` | Quando o payload contém dados inválidos ou campos ausentes. |
| `Kobana::Errors::UnauthorizedError` | Quando a API key é inválida ou expirada. |
| `Kobana::Errors::ApiError` | Quando ocorre um erro inesperado na API Kobana. |
| `Kobana::Errors::BaseError` | Erros genéricos, como falha de rede ou JSON inválido. |

---


## Próximos passos: 

-> subsituir validação com rgex usando libs existentes como validar email ou estados por exemplo.
-> revisar cada campo da API deixando disponível outros na lib
