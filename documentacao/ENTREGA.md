# Arquivos para entrega · N3

**EasyGrade 1.0.0 · build 6 · 21/11/2026**

## Arquivos

- `EasyGrade.apk`: APK final na raiz do projeto, também incluída no ZIP.
- `entrega/EasyGrade-Codigo-Fonte-N3.zip`: projeto completo, documentação e APK, dentro da pasta `EasyGrade/`.
- `entrega/SHA256SUMS.txt`: hashes para conferir os dois arquivos.

O ZIP inclui código Flutter, configuração Android/Web, dependências declaradas, regras do banco, fonte/licença, imagens, testes com suas imagens de referência, README, manual, histórico e roteiro da apresentação.

Foram excluídos `build/`, `.dart_tool/`, `.git/`, `.idea/`, `.gradle/`, `.cxx/`, `node_modules/`, `tmp/`, SDKs, caches, logs, configurações locais do computador e chaves de assinatura. As exclusões não retiram código necessário para reconstruir o aplicativo. O diário de bordo não foi produzido, conforme solicitado.

## Verificações concluídas

- Análise de `lib` e `test`: sem problemas.
- Suíte Flutter: **39 testes passaram**.
- Manual: **18 capturas das telas atuais**, renderizadas com dados fictícios.
- APK: compilação release pelo Gradle; identificação do pacote, versão, assinatura e inclusão da arte do banner conferidas.
- ZIP: integridade, arquivos obrigatórios, correspondência do código e ausência das pastas excluídas conferidas.
- Links locais dos documentos e preservação do histórico conferidos.

O ambiente desta compilação usou Flutter 3.47.2, Dart 3.13.2 e Java 17. As particularidades de cache do computador não são dependências do código entregue.

SHA-256 da APK:

```text
e7bbac35740d320427c0357ca815664c850e458dd833613b3f4f948c4c2c9bd8
```

## Antes de submeter

1. Executar o [roteiro final no Android](VALIDACAO.md#conferência-final-no-android). Não havia aparelho conectado durante esta preparação.
2. Conferir e publicar no GitHub os arquivos finais, o encerramento das Issues e a revisão/aprovação/integração dos PRs. O acesso remoto disponível não permitiu verificar essas situações.
3. Ensaiar e realizar o [pitch](APRESENTACAO.md).
4. Enviar o ZIP do código e a APK conforme o canal de entrega indicado pela professora.

## Usar o pacote

Extraia o ZIP e abra a pasta `EasyGrade/`. O [README](../README.md) explica como executar e compilar. O [manual do usuário](../manual/README.md) explica como operar o aplicativo. Para instalar a atualização, abra a APK no Android e escolha **Atualizar**, mantendo a mesma conta.
