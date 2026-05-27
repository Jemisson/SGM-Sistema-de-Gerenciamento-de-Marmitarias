ultimo executado foi o passo 15 — CashSessions e CashMovements

# SGM - Sistema de Gerenciamento para Marmitaria

Este repositório contém a API do **SGM - Sistema de Gerenciamento para Marmitaria**.

O projeto está sendo desenvolvido como parte das atividades da disciplina de
**Engenharia de Software** do curso de **Doutorado da Universidade Estadual de
Maringá (UEM)**.

## Objetivo

O objetivo do projeto é aplicar conceitos, práticas e técnicas de Engenharia de
Software no desenvolvimento de uma API para apoiar a gestão de uma marmitaria.

Nesta etapa inicial, o foco está na configuração da base técnica do projeto,
sem implementação dos módulos de negócio.

## Stack

- Ruby on Rails API-only
- PostgreSQL
- RSpec
- FactoryBot
- Faker
- Devise
- Devise-JWT
- Pundit
- RSwag / OpenAPI

## Documentação da API

A documentação Swagger/OpenAPI ficará disponível em:

```text
/api-docs
```

## Autorização

A matriz inicial de permissões por perfil está documentada em
[docs/api_authorization.md](docs/api_authorization.md).

## Testes

Para executar a suíte de testes:

```bash
bundle exec rspec
```
