# SGM - Sistema de Gerenciamento para Marmitaria

API REST para gerenciamento operacional e financeiro de uma marmitaria, desenvolvida
com Ruby on Rails em modo API-only.

Este repositório faz parte de um **projeto acadêmico da disciplina de Engenharia de
Software do Doutorado em Ciência da Computação da Universidade Estadual de Maringá
(UEM)**.

## Sobre o projeto

O SGM tem como objetivo apoiar processos essenciais de uma marmitaria, incluindo
cadastro de produtos e insumos, controle de estoque, gestão de cardápios, abertura e
fechamento de caixa, registro de vendas, lançamentos financeiros, relatórios
gerenciais e análises de desempenho.

A API foi estruturada com foco em boas práticas de Engenharia de Software, separação
de responsabilidades, autenticação, autorização por perfil, testes automatizados e
documentação OpenAPI.

## Funcionalidades

- Autenticação com JWT, logout, usuário atual e recuperação de senha
- Gestão de usuários
- Gestão de categorias, fornecedores, insumos, produtos e receitas
- Controle de movimentações de estoque
- Gestão de cardápios e cardápio vigente
- Abertura, acompanhamento e fechamento de caixa
- Registro, consulta e cancelamento de vendas
- Lançamentos financeiros manuais
- Relatórios de visão geral, vendas, estoque e financeiro
- Análises de curva ABC, rentabilidade, tendências, desempenho de produtos e consumo de insumos
- Logs de auditoria
- Autorização por perfis: `admin`, `manager` e `cashier`

## Stack técnica

- Ruby on Rails 8.1 em modo API-only
- PostgreSQL
- Devise
- Devise JWT
- Pundit
- Kaminari
- Active Storage
- RSpec
- FactoryBot
- Faker
- RSwag / OpenAPI
- Brakeman, Bundler Audit e RuboCop Rails Omakase

## Arquitetura

O projeto segue a organização padrão do Ruby on Rails, com camadas adicionais para
manter a regra de negócio isolada dos controllers:

- `app/controllers`: endpoints da API
- `app/models`: entidades de domínio e validações
- `app/services`: operações de negócio e geração de relatórios/análises
- `app/policies`: regras de autorização com Pundit
- `app/serializers`: serialização das respostas JSON
- `spec`: testes automatizados
- `swagger/v1/swagger.yaml`: contrato OpenAPI da API
- `docs/api_authorization.md`: matriz de autorização por perfil

## Requisitos

- Ruby compatível com Rails 8.1
- PostgreSQL
- Bundler

## Configuração

Clone o repositório e instale as dependências:

```bash
bundle install
```

Configure o banco de dados PostgreSQL conforme o arquivo `config/database.yml`.
Por padrão, o projeto usa:

```text
host: 127.0.0.1
port: 5432
username: postgres
password: postgres
```

Prepare o banco de dados:

```bash
bin/rails db:prepare
```

Opcionalmente, carregue os dados iniciais:

```bash
bin/rails db:seed
```

## Execução

Inicie a aplicação localmente:

```bash
bin/rails server
```

A API ficará disponível em:

```text
http://localhost:3000
```

Endpoint de saúde da aplicação:

```text
GET /up
```

## Documentação da API

A documentação interativa Swagger/OpenAPI fica disponível em:

```text
http://localhost:3000/api-docs
```

O contrato OpenAPI também pode ser consultado diretamente em
`swagger/v1/swagger.yaml`.

## Autenticação

A autenticação é baseada em token JWT. Os principais endpoints estão em:

```text
POST   /api/v1/auth/login
DELETE /api/v1/auth/logout
GET    /api/v1/auth/me
POST   /api/v1/auth/password
PATCH  /api/v1/auth/password
```

Após o login, as requisições protegidas devem enviar o token no cabeçalho
`Authorization`:

```text
Authorization: Bearer <token>
```

## Autorização

A autorização é aplicada com Pundit e considera os perfis:

- `admin`
- `manager`
- `cashier`

A matriz de permissões está documentada em
[docs/api_authorization.md](docs/api_authorization.md).

## Testes

Execute a suíte de testes com:

```bash
bundle exec rspec
```

O projeto possui testes de models, services, policies, requests e integração com a
documentação OpenAPI.

## Qualidade e segurança

Scripts auxiliares disponíveis em `bin/`:

```bash
bin/rubocop
bin/brakeman
bin/bundler-audit
```

Também é possível executar o pipeline local de verificação:

```bash
bin/ci
```

## Licença

Este projeto foi desenvolvido para fins acadêmicos. Caso seja necessário reutilizar
ou distribuir o código, verifique previamente as condições definidas pelos autores e
pela disciplina.
