# Autorização da API SGM

A API usa Pundit para aplicar autorização por perfil.

Perfis disponíveis:

- `admin`
- `manager`
- `cashier`

## Matriz inicial de permissões

| Módulo / ação | admin | manager | cashier |
| --- | --- | --- | --- |
| Gerenciar usuários | Sim | Não | Não |
| Gerenciar categorias | Sim | Sim | Não |
| Gerenciar fornecedores | Sim | Sim | Não |
| Gerenciar insumos | Sim | Sim | Não |
| Gerenciar produtos | Sim | Sim | Não |
| Gerenciar receitas | Sim | Sim | Não |
| Gerenciar cardápios | Sim | Sim | Não |
| Registrar venda direta | Não | Não | Sim |
| Abrir, acompanhar e fechar caixa | Não | Sim | Sim |
| Visualizar relatórios | Sim | Sim | Não |
| Visualizar análises | Sim | Sim | Não |
| Visualizar financeiro | Não | Sim | Não |
| Visualizar logs | Sim | Sim | Não |

## Policies base

As permissões compartilhadas ficam em `ApplicationPolicy`.

Policies preparadas para os próximos módulos:

- `UserPolicy`
- `ManagementPolicy`
- `SalePolicy`
- `CashRegisterPolicy`
- `ReportPolicy`
- `AnalyticsPolicy`
- `FinancialPolicy`
- `LogPolicy`

## Uso esperado em controllers

Exemplo para um módulo futuro de usuários:

```ruby
authorize User, :create?
```

Exemplo para um módulo futuro de vendas:

```ruby
authorize :sale, :create?
```

A API retorna `403 Forbidden` em acessos negados, no formato JSON padronizado:

```json
{
  "errors": [
    {
      "field": "base",
      "message": "You are not authorized to perform this action."
    }
  ]
}
```
