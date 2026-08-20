# Task 008 - Criar Tela com Gráfico de Tarefas por Prioridade

## 📋 Informações da Task

**Tipo:** feat  
**Agente Responsável:** dev  
**Branch:** feature/008-feat-tela-grafico-tarefas-por-prioridade  
**Branch Base:** bia-desafio-agosto

---

## 🎯 Objetivo

Criar uma nova tela que exiba um gráfico visual mostrando o número de tarefas agrupadas por prioridade (Importante vs Não Importante), utilizando componentes de gráfico do shadcn/ui. A tela deve ser acessível através de um link adicionado no Header da aplicação.

---

## 📝 Descrição Detalhada

Implementar uma página de analytics que mostre visualmente a distribuição das tarefas por prioridade. O usuário deve conseguir acessar essa página através de um link no header da aplicação (ao lado do link "Versão").

### Requisitos Funcionais:
- Criar nova rota `/analytics` ou `/dashboard`
- Adicionar link de navegação no Header (ex: "Gráficos" ou "Dashboard")
- Exibir gráfico com contagem de tarefas por prioridade
- Tipos de gráfico sugeridos: Bar Chart ou Pie Chart
- Mostrar dados atualizados baseados nas tarefas existentes
- Design responsivo (funcionar em mobile e desktop)

### Requisitos Técnicos:
- Utilizar shadcn/ui para componentes de gráfico
- Biblioteca de gráficos: Recharts (padrão do shadcn)
- Integrar com o estado de `tasks` do App.jsx
- Seguir padrão de rotas do React Router já existente
- Manter consistência visual com o tema da aplicação (dark/light mode)

---

## 🔧 Implementação Técnica

### 1. Instalação de Dependências

**shadcn/ui** requer configuração inicial. Como o projeto usa Vite, será necessário:

```bash
# Instalar dependências base do shadcn
npm install tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Instalar dependências do shadcn/ui
npm install class-variance-authority clsx tailwind-merge
npm install @radix-ui/react-slot

# Instalar Recharts (biblioteca de gráficos)
npm install recharts

# Instalar lucide-react (ícones do shadcn)
npm install lucide-react
```

**Observação:** Se shadcn/ui for complexo demais para o contexto educacional, considerar alternativa mais simples como `react-chartjs-2` ou `victory`.

### 2. Arquivos a Criar/Modificar

#### Novo Componente: `client/src/components/Analytics.jsx`
```javascript
import React from "react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

const Analytics = ({ tasks }) => {
  // Processar dados
  const importantes = tasks.filter(t => t.importante).length;
  const naoImportantes = tasks.filter(t => !t.importante).length;
  
  const data = [
    { name: "Importante", quantidade: importantes },
    { name: "Não Importante", quantidade: naoImportantes }
  ];

  return (
    <div className="analytics-container">
      <h2>Dashboard de Tarefas</h2>
      <div className="chart-wrapper">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="quantidade" fill="#10b981" />
          </BarChart>
        </ResponsiveContainer>
      </div>
      
      <div className="stats-summary">
        <div className="stat-card">
          <h3>Total de Tarefas</h3>
          <p className="stat-value">{tasks.length}</p>
        </div>
        <div className="stat-card">
          <h3>Importantes</h3>
          <p className="stat-value">{importantes}</p>
        </div>
        <div className="stat-card">
          <h3>Não Importantes</h3>
          <p className="stat-value">{naoImportantes}</p>
        </div>
      </div>
    </div>
  );
};

export default Analytics;
```

#### Modificar: `client/src/App.jsx`
- Importar o componente `Analytics`
- Adicionar nova rota no `<Routes>`
- Passar prop `tasks` para o componente

```javascript
import Analytics from "./components/Analytics.jsx";

// Dentro do return, adicionar rota:
<Route path="/analytics" element={<Analytics tasks={tasks} />} />
```

#### Modificar: `client/src/components/Header.jsx`
- Adicionar link para `/analytics` ao lado do link "Versão"

```javascript
<Link to="/analytics" title="Ver dashboard de tarefas">
  Dashboard
</Link>
```

### 3. Estilização

Criar CSS para `.analytics-container`, `.chart-wrapper`, `.stats-summary`, `.stat-card` mantendo consistência com o tema atual.

**Sugestão de estrutura:**
- Container principal com padding
- Gráfico centralizado e responsivo
- Cards de estatísticas em grid (3 colunas desktop, 1 coluna mobile)
- Respeitar variáveis CSS do tema (dark/light mode)

---

## ✅ Checklist de Implementação

### Pré-requisitos
- [ ] Verificar se está no branch `bia-desafio-agosto`
- [ ] Se não estiver, perguntar autorização para retornar ao branch base
- [ ] Após autorizado, mover esta task para `.kiro/tasks/doing/`
- [ ] Fazer commit e push da movimentação no branch `bia-desafio-agosto`
- [ ] Criar worktree: `git worktree add -b feature/008-feat-tela-grafico-tarefas-por-prioridade .worktrees/008-feat-analytics bia-desafio-agosto`
- [ ] Entrar no worktree: `cd .worktrees/008-feat-analytics`
- [ ] Confirmar que está na branch correta: `git branch --show-current`

### Análise e Decisão Técnica
- [ ] Avaliar complexidade do shadcn/ui vs. Recharts puro
- [ ] Decidir qual biblioteca usar (priorizar simplicidade para alunos)
- [ ] Se shadcn for muito complexo, usar Recharts diretamente
- [ ] Documentar decisão tomada

### Desenvolvimento
- [ ] Instalar dependências necessárias no `client/`
- [ ] Criar componente `Analytics.jsx`
- [ ] Implementar lógica de contagem de tarefas por prioridade
- [ ] Implementar gráfico (Bar Chart ou Pie Chart)
- [ ] Adicionar cards de estatísticas (Total, Importantes, Não Importantes)
- [ ] Modificar `App.jsx` para adicionar rota `/analytics`
- [ ] Passar prop `tasks` para o componente Analytics
- [ ] Modificar `Header.jsx` para adicionar link "Dashboard" ou "Gráficos"
- [ ] Criar CSS responsivo para a nova tela
- [ ] Garantir compatibilidade com tema dark/light

### Testes Locais
- [ ] Rodar frontend: `npm run dev` (dentro de `client/`)
- [ ] Acessar a rota `/analytics` pelo navegador
- [ ] Verificar se o gráfico está renderizando corretamente
- [ ] Criar algumas tarefas e validar que os números batem
- [ ] Alternar prioridade de tarefas e verificar atualização do gráfico
- [ ] Testar navegação do link no Header
- [ ] Testar em diferentes resoluções (desktop e mobile)
- [ ] Verificar se o tema dark/light está funcionando no gráfico
- [ ] Verificar se não há erros no console

### Qualidade de Código
- [ ] Código seguindo padrões do projeto
- [ ] Nomes de variáveis claros e em português
- [ ] Componente modular e reutilizável
- [ ] CSS organizado e responsivo
- [ ] Sem warnings ou erros no console

### Finalização
- [ ] Fazer commit das mudanças: `git add . && git commit -m "feat: adicionar tela de analytics com gráfico de tarefas por prioridade"`
- [ ] Push do branch: `git push origin feature/008-feat-tela-grafico-tarefas-por-prioridade`
- [ ] Criar Pull Request com template adequado
- [ ] Informar ao PO que a task está pronta para validação

---

## 🧪 Critérios de Aceite

1. ✅ Nova rota `/analytics` acessível e funcionando
2. ✅ Link no Header levando para a tela de analytics
3. ✅ Gráfico visual mostrando contagem de tarefas por prioridade
4. ✅ Dados do gráfico atualizados em tempo real com as tarefas
5. ✅ Cards de estatísticas (Total, Importantes, Não Importantes) funcionando
6. ✅ Layout responsivo (mobile e desktop)
7. ✅ Compatível com tema dark/light mode
8. ✅ Navegação funcionando corretamente (voltar para home, etc.)
9. ✅ Sem erros no console do navegador
10. ✅ Código simples e educacional (público-alvo: alunos)

---

## 📚 Referências

### Opção 1: shadcn/ui (Mais Completo)
- [shadcn/ui - Chart Components](https://ui.shadcn.com/docs/components/chart)
- [Recharts - Documentação](https://recharts.org/)
- [shadcn/ui - Installation Guide](https://ui.shadcn.com/docs/installation/vite)

### Opção 2: Recharts Direto (Mais Simples)
- [Recharts - Getting Started](https://recharts.org/en-US/guide)
- [Recharts - BarChart Example](https://recharts.org/en-US/examples/SimpleBarChart)
- [Recharts - PieChart Example](https://recharts.org/en-US/examples/TwoLevelPieChart)

### React Router
- [React Router - Routes](https://reactrouter.com/en/main/components/routes)

---

## ⚠️ Observações Importantes

### Simplicidade é Prioridade
- **Público-alvo:** Alunos em aprendizado
- **Filosofia:** Simplicidade acima de complexidade
- Se shadcn/ui exigir muita configuração inicial (Tailwind, etc.), preferir Recharts puro
- Não over-engineer: um gráfico simples e funcional é melhor que algo complexo

### Decisão de Biblioteca
- **shadcn/ui:** Mais moderno, mas requer setup de Tailwind
- **Recharts puro:** Mais direto, menos dependências
- **Recomendação:** Avaliar o esforço e escolher o mais educacional

### Alternativas Simples
Se Recharts for complexo, considerar:
- **Chart.js com react-chartjs-2:** Muito popular e simples
- **Victory:** Alternativa leve e educacional

### Dados em Tempo Real
- O componente recebe `tasks` como prop do App.jsx
- Sempre que tasks mudam, o gráfico deve atualizar automaticamente
- React cuida disso se implementado corretamente

---

## 🔄 Fluxo de Finalização (Executado pelo PO)

Quando o agente DEV concluir todas as etapas:
1. Informar ao PO que a task está pronta
2. PO irá validar se:
   - [ ] Todos os itens do checklist foram marcados
   - [ ] Pull Request foi criado corretamente
   - [ ] Código está implementado conforme especificação
   - [ ] Critérios de aceite foram atendidos
   - [ ] Gráfico está funcional e responsivo
3. PO fará:
   - [ ] Revisão do PR no GitHub
   - [ ] Validação funcional da tela de analytics
   - [ ] Merge do PR para `bia-desafio-agosto`
   - [ ] Remoção do worktree: `git worktree remove .worktrees/008-feat-analytics`
   - [ ] Mover task para `.kiro/tasks/done/`
   - [ ] Commit e push da finalização

---

**Task criada em:** $(date +%d/%m/%Y)  
**Criada por:** PO
