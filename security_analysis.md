# Relatório de Análise de Segurança - Feira Fácil

Este documento apresenta uma análise de segurança técnica do aplicativo Feira Fácil, com foco na proteção de dados dos usuários e integridade da plataforma.

## 1. Segurança de Banco de Dados (Firestore)

> [!NOTE]
> **Status: Implementado**
> Foram criadas regras de segurança robustas no arquivo `firestore.rules` que restringem o acesso aos dados apenas para membros de cada grupo.

### Pontos Chave:
- **Controle de Acesso:** Usuários só podem ler/escrever em grupos onde seu `uid` esteja na lista `memberIds`.
- **Perfil do Usuário:** Somente o próprio dono pode acessar e gerenciar seu perfil.

## 2. Gestão de Chaves de API

As chaves do Firebase e do Google Places estão expostas no código-fonte (`firebase_options.dart` e `places_service.dart`).

### Ações Necessárias:
- **Restrições de API:** No [Google Cloud Console](https://console.cloud.google.com/), restrinja a chave do Google Places para aceitar apenas requisições vindas do domínio do app Web (`feira-facil-a0037.web.app`) e do Package ID do Android.
- **Quota Limiting:** Configure alertas de faturamento para evitar surpresas.

## 3. Autenticação e Gestão de Grupos

O sistema utiliza Google Sign-In, delegando a segurança da conta para o Google.

### Pontos de Atenção:
- **Brute Force (Convites):** O código de 6 dígitos é seguro, mas no futuro pode ser adicionado um limite de tentativas via Cloud Functions para evitar scripts maliciosos.

## 4. Privacidade e LGPD

O aplicativo possui telas de termos e política, além de fluxo de exclusão de conta.

### Recomendações:
- **Check-up de Segurança:** Rode periodicamente o comando `dart pub deps --dev` para verificar vulnerabilidades em dependências.
