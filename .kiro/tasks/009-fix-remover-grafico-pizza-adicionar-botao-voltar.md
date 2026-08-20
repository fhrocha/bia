# Task 009 - Remover Gráfico de Pizza e Adicionar Botão Voltar no Dashboard

## Tipo
fix

## Descrição
Ajustar a tela de Dashboard de Tarefas (Analytics) para remover o gráfico de pizza e adicionar um botão para retornar à tela principal da aplicação BIA.

## Contexto
Durante a revisão da tela de Dashboard, foram identificadas duas necessidades:
1. O gráfico de pizza não está sendo útil e duplica informação já presente no gráfico de barras
2. Falta um botão de navegação para voltar à tela principal

## Modelo de Trabalho
Esta task segue o modelo **feature/branch + worktree**:
- Branch base: `bia-desafio-agosto`
- Branch da task: `feature/009-fix-remover-grafico-pizza-adicionar-botao-voltar`
- Worktree: `.worktrees/009-fix-analytics`

## Agente Responsável
**dev** - Responsável pela implementação frontend

## Pré-requisitos
- [ ] Verificar se está no branch `bia-desafio-agosto`
- [ ] Se não estiver, perguntar se pode retornar para o branch antes de iniciar

## Implementação

### 1. Preparação do Ambiente
- [ ] Mover esta task para `.kiro/tasks/doing/`
- [ ] Fazer commit e push no branch `bia-desafio-agosto`
- [ ] Criar worktree: `git worktree add -b feature/009-fix-remover-grafico-pizza-adicionar-botao-voltar .worktrees/009-fix-analytics bia-desafio-agosto`
- [ ] Entrar no worktree: `cd .worktrees/009-fix-analytics`
- [ ] Confirmar branch correto: `git branch --show-current`

### 2. Alterações no Componente Analytics

**Arquivo:** `client/src/components/Analytics.jsx`

#### 2.1. Atualizar Imports
- [ ] Remover `PieChart`, `Pie` e `Cell` das importações do recharts
- [ ] Adicionar `useNavigate` do react-router-dom
- [ ] Import final deve ser:
```javascript
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { useNavigate } from "react-router-dom";
```

#### 2.2. Adicionar Hook de Navegação
- [ ] Dentro do componente `Analytics`, adicionar:
```javascript
const navigate = useNavigate();
```

#### 2.3. Remover Código do Gráfico de Pizza
- [ ] Remover a constante `dataPie`
- [ ] Remover a constante `COLORS`
- [ ] Remover toda a seção `<div className="chart-wrapper">` do gráfico de pizza
- [ ] Manter apenas o gráfico de barras

#### 2.4. Adicionar Botão Voltar
- [ ] Adicionar botão no início do `<div className="analytics-header">`, **antes** do `<h2>`
- [ ] Código do botão:
```javascript
<button 
  onClick={() => navigate('/')} 
  className="btn-back"
  title="Voltar para tela principal"
>
  ← Voltar
</button>
```

### 3. Adicionar Estilos CSS

**Arquivo:** `client/src/index.css`

- [ ] Adicionar ao final do arquivo:
```css
/* Botão Voltar do Analytics */
.btn-back {
  background: var(--accent-primary);
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s ease;
  margin-bottom: 1rem;
}

.btn-back:hover {
  background: var(--accent-hover);
  transform: translateX(-2px);
}

.btn-back:active {
  transform: translateX(-4px);
}
```

### 4. Testes Locais

#### 4.1. Build e Execução
- [ ] Instalar dependências (se necessário): `npm install`
- [ ] Build do frontend: `cd client && npm run build`
- [ ] Verificar que o build foi concluído com sucesso
- [ ] Confirmar redução no tamanho do bundle JS (deve diminuir ~19-20 KB)

#### 4.2. Teste com Docker Compose
- [ ] Voltar ao diretório raiz do worktree
- [ ] Build do Docker: `docker compose build`
- [ ] Subir containers: `docker compose up -d`
- [ ] Aguardar containers iniciarem

#### 4.3. Validações Funcionais
- [ ] Acessar http://localhost:3001
- [ ] Navegar para o Dashboard (clicar em "Dashboard" no header)
- [ ] **Verificar:** Botão "← Voltar" está visível no topo da página
- [ ] **Verificar:** Apenas gráfico de barras está sendo exibido
- [ ] **Verificar:** Gráfico de pizza foi removido
- [ ] **Testar:** Clicar no botão "← Voltar" e confirmar que retorna à home
- [ ] **Testar:** Animação do botão ao passar o mouse (hover)
- [ ] **Testar:** Funcionalidade em tema claro e escuro

#### 4.4. Validações Técnicas
- [ ] Verificar console do navegador para erros
- [ ] Confirmar que não há imports não utilizados
- [ ] Verificar que o código está limpo (sem código comentado relacionado ao PieChart)

### 5. Commit e Push
- [ ] Parar containers: `docker compose down`
- [ ] Adicionar arquivos alterados: `git add client/src/components/Analytics.jsx client/src/index.css`
- [ ] Commit: `git commit -m "fix: remover gráfico de pizza e adicionar botão voltar no dashboard"`
- [ ] Push: `git push origin feature/009-fix-remover-grafico-pizza-adicionar-botao-voltar`

### 6. Informar Conclusão
- [ ] Informar ao PO que a task está concluída e pronta para revisão
- [ ] Mencionar que todos os testes foram executados com sucesso
- [ ] Aguardar PO para criação do PR e finalização

## Critérios de Aceite
- [ ] Gráfico de pizza completamente removido do código e da interface
- [ ] Botão "← Voltar" visível e funcional no topo da página Analytics
- [ ] Botão redireciona corretamente para a home (`/`)
- [ ] Estilo do botão está consistente com o design da aplicação
- [ ] Animações do botão funcionando corretamente
- [ ] Sem erros no console do navegador
- [ ] Build do frontend reduzido em tamanho (~19-20 KB)
- [ ] Funcionalidade testada em tema claro e escuro

## Observações Técnicas
- O `useNavigate` é a forma recomendada no React Router v6 para navegação programática
- A remoção do PieChart reduzirá o tamanho do bundle final
- Os cards de estatísticas devem ser mantidos (não alterar)
- O gráfico de barras deve permanecer inalterado

## Finalização pelo PO
Após a implementação ser concluída pelo agente **dev**, o PO deverá:
- [ ] Revisar todas as alterações implementadas
- [ ] Verificar se todos os itens do checklist foram marcados
- [ ] Validar os critérios de aceite
- [ ] Testar a aplicação localmente
- [ ] Criar Pull Request da branch `feature/009-fix-remover-grafico-pizza-adicionar-botao-voltar` para `bia-desafio-agosto`
- [ ] Após merge aprovado, remover o worktree: `git worktree remove .worktrees/009-fix-analytics`
- [ ] Mover task para `.kiro/tasks/done/`
- [ ] Fazer commit e push final da movimentação da task
- [ ] Informar ao usuário que a task foi finalizada com sucesso
