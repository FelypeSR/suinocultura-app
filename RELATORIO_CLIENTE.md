# GSPR — Aplicativo de Gestão de Suinocultura
### Relatório de Progresso

**Data:** 27/06/2026
**Plataforma:** Aplicativo (Flutter) com banco de dados em nuvem (Firebase)

---

## Resumo

O aplicativo já está funcional, com login, cadastro de informações da granja e um painel inicial que resume os dados em tempo real. Abaixo está o que já foi entregue até o momento.

---

## ✅ O que já está pronto

### 🔐 Acesso e segurança
- **Login com e-mail e senha**
- **Login com conta Google** (entra com um toque, exibindo a foto de perfil)
- **Cadastro de novos usuários**
- **Recuperação de senha** por e-mail
- O app reconhece automaticamente se o usuário está logado e leva direto para a tela certa

### 🏠 Tela inicial (Painel)
- Saudação personalizada com nome e foto do produtor
- Barra de pesquisa
- Destaque para os **próximos eventos** (ex.: dia de vacinação)
- **Carrossel de resumo** com 4 painéis que mostram os números da granja:
  1. **Estoque** — quantidade de ração, rebanho, leitões e % de ração
  2. **Leitões** — nascimentos, desmames e mortalidade
  3. **Anotações** — observações registradas no sistema
  4. **Cobertura** — fêmeas em cobertura, gestantes e em aleitamento
- **Painel lateral** com opções de perfil, configurações e sair

### 🐷 Cadastro e controle de animais
- **Cadastro de animais** com gravação no banco de dados em nuvem
- **Registro de vacinação**
- **Editar suíno** — pela opção central, é possível abrir um animal e registrar mudanças conforme o sexo:
  - **Fêmeas:** *Transformar em gestante* (informa o macho usado e a data da cobertura; o sistema calcula automaticamente a previsão de parto, ~114 dias) e *Registrar venda*
  - **Machos:** *Registrar cobertura* (conta o nº de coberturas do reprodutor) e *Registrar venda*
- **Registro de venda** com comprador, valor e data; o animal passa a aparecer com a situação "Vendido"
- Filtro rápido por **Todos / Machos / Fêmeas** ao editar

### 🌾 Estoque de ração
- Cadastro de entradas de ração (tipo, fornecedor, quantidade e custo)
- **Controle de saldo automático** — o sistema desconta o consumo diário e mostra quanto ainda resta
- **Aviso de ração acabando** — alerta quando o estoque está perto do fim (ex.: "Acaba em 3 dias")
- Classificação da ração por grupo de animais (todos, fêmeas, machos, filhotes)
- Campo de observações por entrada
- **Reaproveitamento das rações já usadas** — ao registrar uma nova entrada, o produtor escolhe de uma lista que junta os tipos sugeridos com as rações que já cadastrou, ou adiciona uma ração nova na hora (evita digitar de novo e padroniza os nomes)

### 📄 Relatório da granja (PDF)
- Geração de um **relatório completo em PDF** para imprimir, salvar ou compartilhar
- Reúne **rebanho, vendas, ninhadas/leitões e ração** em seções organizadas
- **Nova seção de Vendas** — total de animais vendidos, valor total arrecadado, valor médio por animal e a lista de vendas (data, código, comprador e valor)
- Cabeçalho com a **identidade visual do app** (logo do GSPR)

---

## 🔄 Próximos passos (planejados)
- Conectar os números do painel inicial 100% aos dados reais do banco
- Edição de perfil e gestão de usuários
- Melhorias visuais e **animações** na navegação
- Refinamentos de layout

---

*Qualquer dúvida ou ajuste de prioridade, estamos à disposição.*