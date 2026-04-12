# 🛒 FeiraFacil — Plano de Criação de App Mobile Android

---

## 1. Visão Geral do Produto

**Nome:** Feira Fácil  
**Posicionamento:** Organize, compare preços e economize na sua feira sem complicação.  
**Plataforma:** Android (nativo ou cross-platform)
**Público-alvo:** Famílias e grupos domésticos que fazem compras em supermercados diferentes
**Proposta de valor:** Organizar a lista de compras por categoria, cadastrar preços em múltiplos mercados e compartilhar tudo em tempo real com a família, permitindo encontrar a opção de compra mais econômica.

---


---

## 2. Funcionalidades Principais (MVP)

### 2.1 — Gerenciamento de Itens
- Cadastro de alimentos com nome, unidade de medida e categoria
- Categorias padrão: Hortifruti, Carnes & Peixes, Laticínios, Padaria, Bebidas, Grãos & Cereais, Congelados, Limpeza, Higiene, Outros
- Possibilidade de criar categorias personalizadas
- **Marca do produto** como campo obrigatório — o mesmo item (ex: "Iogurte Natural") pode ter registros de preço para marcas diferentes (Activia, Vigor, marca própria do mercado etc.)
- O par **item + marca** forma a identidade do produto para fins de comparação de preço
- Foto do produto (opcional)
- Marcação de item como "favorito" para lista rápida

### 2.2 — Lista de Feira
- Criação de listas de compras (ex: "Feira do mês", "Churrasco", "Compra rápida")
- **Cor por lista:** seletor de cor na criação para diferenciar listas visualmente
- Adicionar itens da base de dados ou criar novo
- **Itens favoritos:** produtos marcados como favorito aparecem em atalho rápido na hora de montar a lista — útil para itens comprados toda feira
- Definir quantidade desejada por item
- **Filtros dentro da lista: Todos / Pendentes / Pegos** — no modo compra o usuário filtra só o que ainda não pegou e foca
- Marcar itens como "Peguei!" durante a compra
- **Display de meta com percentual:** "Meta 12% 🟢 · R$ 36,00 de R$ 300,00" — mais legível do que só barra de cor
- Subtotal estimado atualizado em tempo real conforme itens são marcados

### 2.3 — Cadastro de Mercados
- Nome do mercado
- Endereço / bairro
- Observações (ex: "Aberto até 22h", "Tem fila no caixa rápido")
- Avaliação geral (estrelas)

### 2.4 — Cadastro de Preços
- Associar produto + marca + mercado + preço + data de registro
- **Preço progressivo por quantidade (faixas de preço):** um mesmo produto pode ter múltiplas faixas cadastradas
  - Ex: Iogurte Activia — 1 unidade: R$ 18,00 | a partir de 3 unidades: R$ 16,90/un
  - Ex: Refrigerante — 1 lata: R$ 4,50 | pack com 6: R$ 3,80/un
  - O app armazena todas as faixas e usa a mais vantajosa automaticamente ao calcular o total, de acordo com a quantidade que o usuário colocar no carrinho
- Campo para observação (ex: "Promoção válida até domingo", "Só na gôndola do fundo")
- Histórico de variação de preço por produto/mercado

#### Modelo de faixa de preço (Preço Progressivo)
Cada registro de preço pode ter uma ou mais faixas:

| Quantidade mínima | Preço unitário |
|---|---|
| 1 | R$ 18,00 |
| 3 | R$ 16,90 |

O app sempre aplica a faixa mais vantajosa conforme a quantidade escolhida na lista.

### 2.4b — Cadastro de Preços por Foto de Etiqueta (OCR)

Para eliminar o atrito de digitar preços manualmente, o app permite fotografar a etiqueta de preço na gôndola do mercado. O app lê a imagem, extrai as informações e apresenta um formulário pré-preenchido para o usuário revisar e confirmar (ou corrigir) antes de salvar.

---

#### Fluxo completo

```
[Botão "Fotografar Etiqueta"]
        │
        ▼
[Câmera abre em modo etiqueta]
  — guia visual de enquadramento
  — dica: "Centralize a etiqueta e mantenha firme"
        │
        ▼
[Foto capturada]
        │
        ▼
[ML Kit (on-device) extrai texto bruto da imagem]
  — rápido, gratuito, funciona offline
        │
        ▼
[Gemini Vision API interpreta o texto bruto]
  — identifica: nome do produto, marca, preço unitário,
    faixas promocionais, unidade de medida
  — retorna JSON estruturado
        │
        ▼
[Tela de Confirmação/Correção]
  — campos pré-preenchidos, todos editáveis
  — sugestão de produto da base (se existir match)
  — usuário confirma, corrige ou descarta
        │
        ▼
[Preço salvo com foto da etiqueta como evidência]
```

---

#### O que o app tenta extrair de cada etiqueta

| Campo | Exemplo extraído | Notas |
|---|---|---|
| Nome do produto | "IOGURTE NATURAL INTEGRAL" | Normalizado para comparação |
| Marca | "ACTIVIA" | Nem sempre presente na etiqueta |
| Preço unitário | R$ 18,00 | Campo obrigatório |
| Faixa promocional | "LEVE 3 POR R$ 50,70" | Converte para R$ 16,90/un automaticamente |
| Unidade de medida | "170g", "UN", "KG" | Extraída do texto ou inferida |
| Validade da promoção | "ATÉ 15/02" | Salvo como observação |

---

#### Tela de Confirmação / Correção

Esta tela é o passo mais importante do fluxo — o OCR não é perfeito, então o usuário sempre revisa antes de salvar.

**Layout:**
- Miniatura da foto tirada (para referência visual) no topo
- Campos editáveis pré-preenchidos:
  - **Produto:** campo com autocomplete sugerindo itens já cadastrados na base do grupo. Se o OCR leu "IOGURTE NATURAL INTEGRAL ACTIVIA 170G", o app sugere "Iogurte Natural — Activia" da base
  - **Marca:** pré-preenchida ou campo para digitar
  - **Mercado:** pré-selecionado (o mercado ativo da sessão de compra, se houver)
  - **Faixas de preço:** exibidas como tabela editável. Se o OCR detectou promoção por quantidade, já aparecem as 2 faixas preenchidas. O usuário pode adicionar, remover ou corrigir qualquer faixa
  - **Observação:** campo livre (ex: "Promoção válida até domingo")
- Botão **"Confirmar e Salvar"** e botão **"Descartar"**
- Opção **"Fotografar novamente"** se a leitura ficou ruim

**Comportamento quando o produto não é reconhecido:**
- Campo produto fica em branco com placeholder "Produto não identificado — selecione ou cadastre"
- O usuário seleciona da base existente ou cria um produto novo
- O preço (se lido corretamente) já está preenchido — o esforço é só associar ao produto certo

---

#### Stack técnica para OCR

| Etapa | Tecnologia | Custo | Funciona offline? |
|---|---|---|---|
| Captura e pré-processamento da imagem | ML Kit Text Recognition v2 | Gratuito | ✅ Sim |
| Interpretação semântica do texto bruto | Gemini 1.5 Flash API | ~R$ 0,01–0,05 por foto | ❌ Requer internet |
| Fallback sem internet | Parser local com regex de padrões de etiqueta BR | Gratuito | ✅ Sim |

**Sobre o custo do Gemini:** Para uso familiar (estimativa de 5–20 fotos por semana), o custo mensal ficaria na faixa de R$ 0,50 a R$ 4,00 — praticamente desprezível. No plano gratuito do Gemini API há cota suficiente para começar sem pagar nada.

**Parser local como fallback (modo offline):** Quando não há internet, o app usa regex contra padrões comuns de etiquetas brasileiras:
```
Padrões reconhecidos:
  R$ XX,XX            → preço unitário
  LEVE \d+ POR R\$    → faixa promocional
  \d+[Gg] / \d+[Mm][Ll] / [Kk][Gg] → unidade de medida
```
Menos preciso que o Gemini, mas suficiente para a maioria das etiquetas simples.

---

#### Foto da etiqueta como evidência

Ao salvar o preço via OCR, a foto da etiqueta é armazenada no Firebase Storage e associada ao registro de preço. Isso serve para:
- Outros membros da família verem a etiqueta original se quiserem conferir
- Resolver dúvidas ("será que esse preço tá certo?")
- Histórico visual de variação de preço ao longo do tempo

---

### 2.5 — Comparador de Preços
- Selecionar um ou mais itens e ver todos os preços cadastrados por mercado
- Ordenar por menor preço
- Destacar o mercado mais barato para cada item
- "Simulação de feira": escolher os itens da lista e calcular qual mercado fica mais barato no total (com opção de comprar tudo em um só lugar ou dividir entre mercados)
- Alerta de preço desatualizado (ex: cadastrado há mais de 14 dias)

### 2.7 — Modo Compra: Carrinho Inteligente com Orçamento

Esta é a funcionalidade de uso dentro do mercado. Com o mercado selecionado e os preços cadastrados, o app vira um carrinho inteligente:

**Fluxo de uso:**
1. Usuário abre a lista de feira e seleciona "Iniciar Compra" no mercado escolhido
2. Define um **orçamento limite** (opcional, mas recomendado)
3. Para cada item da lista, ajusta a quantidade com botões **+** e **−**
4. O app calcula o subtotal em tempo real, aplicando automaticamente a melhor faixa de preço progressivo

**Interface do Modo Compra:**
- **Display de meta com percentual** no topo: "Meta 45% 🟡 · R$ 135,00 de R$ 300,00" + barra de progresso abaixo — mais legível do que só a barra
- A barra e o emoji mudam conforme o total se aproxima do limite: 🟢 verde (< 75%) → 🟡 amarelo (75–90%) → 🔴 vermelho (> 90%)
- Alerta suave (vibração + cor) ao ultrapassar 90% do orçamento
- Alerta de estouro ao ultrapassar 100%
- **Filtros: Todos / Pendentes / Pegos** — permite focar só no que falta pegar, sem distração dos itens já no carrinho
- Cada item exibe: nome, marca, quantidade atual, preço unitário aplicado e subtotal do item
- Quando a quantidade atinge o limiar de uma faixa de preço progressiva, o app exibe um **badge "🏷️ Preço especial ativo!"** e mostra a economia gerada
- Sugestão automática de faixa: se o usuário tem 2 iogurtes no carrinho e existe faixa para 3, o app sugere: *"Adicione +1 iogurte e economize R$ 3,30 no total"*
- Ao marcar "Peguei!" o item muda para acinzentado/riscado e vai para a aba Pegos — continua no total mas sai da visão principal
- Ao finalizar, gera um resumo da compra com total real pago, economia gerada pelas faixas e comparação com o orçamento definido

**Exemplo de cálculo:**
```
Lista: Iogurte Activia x3 + Leite Piracanjuba x2 + Pão de Forma Seven Boys x1

Iogurte: 3 × R$ 16,90 = R$ 50,70  (faixa "3+ unid." aplicada, economizou R$ 3,30)
Leite:   2 × R$ 5,49  = R$ 10,98
Pão:     1 × R$ 9,90  = R$  9,90
─────────────────────────────────
Total:                   R$ 71,58
Orçamento:               R$ 80,00
Saldo restante:          R$  8,42  ✅
```

- Criar ou entrar em um grupo familiar via código de convite ou link
- Até 10 membros por grupo (ajustável)
- Todos os membros compartilham:
  - Base de itens
  - Mercados cadastrados
  - Preços registrados
  - Listas de feira
- Sincronização em tempo real (2 pessoas cadastrando preços ao mesmo tempo veem as atualizações do outro)
- Identificação de quem cadastrou cada preço (avatar/nome do membro)
- Notificação push: "Maria cadastrou preço novo no Assaí!"

---

## 3. Funcionalidades Secundárias (Pós-MVP)

- Histórico de compras (valor gasto por semana/mês)
- Modo offline com sync quando voltar à conexão
- Exportar lista de feira (PDF ou compartilhar por WhatsApp)
- Sugestão automática de lista baseada em histórico
- Scanner de código de barras para identificar produto automaticamente
- Integração com APIs de supermercados (se disponível)
- Widget na tela inicial com o total da lista atual
- Modo "compra em andamento" com interface simplificada (fonte grande, fácil de marcar)

---

## 4. Arquitetura Técnica

### 4.1 — Stack Recomendada

| Camada | Tecnologia | Justificativa |
|---|---|---|
| Mobile | **Kotlin (Android nativo)** ou **Flutter** | Kotlin: melhor performance nativa. Flutter: permite iOS no futuro com o mesmo código |
| Backend | **Firebase** (Firestore + Auth + FCM) | Tempo real nativo, fácil de configurar, plano gratuito generoso para início |
| Banco de dados | **Cloud Firestore** | Sincronização em tempo real e offline-first |
| Autenticação | **Firebase Auth** | Login por e-mail, Google ou número de telefone |
| Notificações | **Firebase Cloud Messaging (FCM)** | Push notifications gratuitas |
| Armazenamento | **Firebase Storage** | Para fotos de produtos |

> **Alternativa ao Firebase:** Supabase (PostgreSQL + Realtime + Auth) — mais controle, open source, boa opção se quiser evitar dependência do Google.

### 4.2 — Modelo de Dados (Firestore)

```
/grupos/{grupoId}
  - nome: string
  - codigoConvite: string
  - membros: [userId, ...]

/grupos/{grupoId}/itens/{itemId}
  - nome: string           (ex: "Iogurte Natural")
  - marca: string          (ex: "Activia") ← novo campo obrigatório
  - categoria: string
  - unidadeMedida: string  (ex: "un", "kg", "L")
  - fotoUrl: string?
  - criadoPor: userId

/grupos/{grupoId}/mercados/{mercadoId}
  - nome: string
  - endereco: string
  - observacoes: string
  - criadoPor: userId

/grupos/{grupoId}/precos/{precoId}
  - itemId: ref
  - mercadoId: ref
  - faixas: [             ← lista de faixas de preço progressivo
      { qtdMinima: 1, precoUnitario: 18.00 },
      { qtdMinima: 3, precoUnitario: 16.90 }
    ]
  - dataRegistro: timestamp
  - registradoPor: userId
  - observacao: string?   (ex: "Promoção válida até domingo")
  - fotoEtiquetaUrl: string?  ← foto da etiqueta como evidência (Firebase Storage)
  - origemCadastro: "manual" | "ocr"  ← rastreia como o preço foi inserido

/grupos/{grupoId}/listas/{listaId}
  - nome: string
  - dataCriacao: timestamp
  - status: "ativa" | "em_compra" | "concluida"
  - orcamento: number?    ← orçamento limite definido pelo usuário
  - mercadoAtivo: ref?    ← mercado selecionado para o modo compra
  - criadoPor: userId

/grupos/{grupoId}/listas/{listaId}/itensLista/{itemListaId}
  - itemId: ref
  - quantidadePlanejada: number
  - quantidadeNoCarrinho: number  ← atualizada durante o modo compra
  - marcado: boolean
  - mercadoEscolhido: mercadoId?
```

#### Lógica de cálculo do preço progressivo
```
function calcularPrecoItem(faixas, quantidade):
  // Ordena faixas por qtdMinima decrescente
  // Aplica a primeira faixa cuja qtdMinima <= quantidade
  melhorFaixa = faixas
    .sort(desc por qtdMinima)
    .find(f => f.qtdMinima <= quantidade)
  return melhorFaixa.precoUnitario * quantidade
```

### 4.3 — Sincronização em Tempo Real

O Firestore possui listeners nativos que disparam atualizações automáticas quando qualquer documento muda. A implementação é direta:

```kotlin
// Exemplo em Kotlin (Android)
db.collection("grupos/$grupoId/precos")
  .addSnapshotListener { snapshots, error ->
      // Chamado automaticamente quando qualquer preço é adicionado/editado
      atualizarUI(snapshots)
  }
```

Isso garante que se Maria cadastra um preço no Assaí enquanto João está vendo a lista de preços, a tela de João atualiza sem precisar recarregar.

---

## 5. Fluxo de Telas (UX)

```
[Splash / Login]
      │
      ▼
[Home]
 ├── Minha Lista de Feira (atalho rápido)
 ├── Comparar Preços
 ├── Novidades da Família (últimos preços cadastrados)
 └── Ações rápidas: + Item | + Preço | 📷 Foto Etiqueta | + Mercado
      │
      ├── [Listas] ──► [Lista de Feira] ──► [Modo Compra]
      │
      ├── [Catálogo de Itens] ──► [Detalhes do Item] ──► [Histórico de Preços]
      │
      ├── [Mercados] ──► [Detalhes do Mercado] ──► [Preços neste Mercado]
      │
      ├── [Comparador] ──► [Simulação de Feira]
      │
      ├── [📷 Câmera OCR] ──► [Tela de Confirmação/Correção] ──► [Preço Salvo]
      │
      └── [Família] ──► [Membros] | [Convidar] | [Atividade Recente]
```

---

## 6. Telas Essenciais

1. **Onboarding** — Criar conta, criar grupo familiar ou entrar em um existente
2. **Home** — Dashboard com resumo da lista ativa e atividade recente da família
3. **Lista de Feira** — Itens agrupados por categoria, com preço estimado e checkbox
4. **Modo Compra / Carrinho Inteligente** — Total em tempo real, barra de orçamento, faixas de preço progressivo automáticas, sugestão de economia
5. **Catálogo de Itens** — Todos os alimentos cadastrados com filtro por categoria e marca
6. **Cadastro de Preço (Manual)** — Fluxo rápido: item → mercado → faixas de preço (1+ campos de faixa)
7. **📷 Câmera OCR** — Modo câmera com guia de enquadramento para fotografar etiqueta
8. **Confirmação OCR** — Formulário pré-preenchido com dados lidos da etiqueta, todos editáveis; miniatura da foto como referência; autocomplete para associar ao produto da base
9. **Comparador** — Tabela de preços por item/marca e por mercado, com destaque do mais barato
10. **Simulação de Feira** — Selecionar lista e ver qual mercado (ou combinação) fica mais barato
11. **Mercados** — Lista e mapa dos mercados cadastrados
12. **Família** — Membros, convite, histórico de atividades

---

## 7. Roadmap de Desenvolvimento

### Fase 1 — MVP (2–3 meses)
- [ ] Autenticação (login e cadastro)
- [ ] Criação e entrada em grupo familiar
- [ ] CRUD de categorias, itens e marcas
- [ ] CRUD de mercados
- [ ] Cadastro de preços com faixas progressivas por quantidade
- [ ] Sincronização em tempo real entre membros
- [ ] Lista de feira com marcação de itens
- [ ] **Modo Compra com total em tempo real e barra de orçamento**
- [ ] **Cálculo automático de melhor faixa de preço progressivo**
- [ ] **Sugestão "adicione +N e economize R$X"**
- [ ] Comparador básico de preços

### Fase 2 — Refinamento (1–2 meses)
- [ ] Modo offline
- [ ] Simulação de feira (qual mercado é mais barato no total)
- [ ] Histórico de preços e gráfico de variação
- [ ] Notificações push
- [ ] Alerta de preço desatualizado
- [ ] **📷 OCR de etiquetas — ML Kit + parser local (fallback offline)**
- [ ] **📷 OCR de etiquetas — integração Gemini Vision para interpretação semântica**
- [ ] **Tela de Confirmação OCR com autocomplete de produto**
- [ ] **Armazenamento da foto de etiqueta como evidência (Firebase Storage)**

### Fase 3 — Expansão (2–3 meses)
- [ ] Scanner de código de barras (complementa o OCR: identifica o produto pelo EAN, OCR captura o preço)
- [ ] Histórico de gastos e relatórios
- [ ] Exportar lista por WhatsApp/PDF
- [ ] Widget de tela inicial
- [ ] Sugestões automáticas de lista

---

## 8. Estimativa de Custos

### Firebase — plano Spark gratuito
| Recurso | Limite gratuito | Suficiente para início? |
|---|---|---|
| Firestore reads | 50.000/dia | ✅ Sim |
| Firestore writes | 20.000/dia | ✅ Sim |
| Autenticação | Ilimitada | ✅ Sim |
| Storage (fotos de etiqueta) | 5 GB | ✅ Sim |
| FCM (notificações) | Gratuito | ✅ Sim |

### Gemini Vision API (OCR inteligente)
| Uso estimado | Custo estimado |
|---|---|
| 5–20 fotos/semana (uso familiar) | ~R$ 0,50 – R$ 4,00/mês |
| Cota gratuita (Gemini 1.5 Flash) | 15 req/min, 1.500 req/dia — suficiente para começar sem pagar |

Para uso familiar, os custos totais são praticamente zero no início.

---

## 9. Próximos Passos Concretos

1. **Definir stack:** Kotlin nativo vs Flutter (recomendo Flutter se quiser flexibilidade futura)
2. **Criar projeto no Firebase** e configurar Firestore + Auth
3. **Prototipar no Figma** as 5 telas principais
4. **Desenvolver o MVP** seguindo a Fase 1 do roadmap
5. **Testar com a família** em uso real antes de publicar na Play Store

---

*Documento gerado como plano de criação — pode ser expandido com wireframes, especificações técnicas detalhadas ou documentação de API conforme o desenvolvimento avançar.*
