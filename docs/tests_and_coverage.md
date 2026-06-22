# Testes e cobertura

Este projeto usa RSpec para testes automatizados e SimpleCov para geração do
relatório de cobertura.

## Executar os testes

Para executar toda a suíte:

```bash
bundle exec rspec
```

Para executar apenas um grupo de specs:

```bash
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/services
```

Para executar um arquivo específico:

```bash
bundle exec rspec spec/models/product_spec.rb
```

## Ver o relatório de cobertura

O relatório do SimpleCov é gerado automaticamente ao executar os testes:

```bash
bundle exec rspec
```

Depois da execução, abra o arquivo abaixo no navegador:

```text
coverage/index.html
```

Também é possível conferir o resumo diretamente no terminal ao final da execução,
por exemplo:

```text
Line Coverage: 98.38% (1825 / 1855)
```

O diretório `coverage/` é gerado localmente e não deve ser versionado.
