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
- [x] Verificar se está no branch `bia-desafio-agosto`
- [x] Se não estiver, perguntar se pode retornar para o branch antes de iniciar

## Implementação

### 1. Preparação do Ambiente
- [x] Mover esta task para `.kiro/tasks/doing/`
- [x] Fazer commit e push no branch `bia-desafio-agosto`
- [x] Criar worktree: `git worktree add -b feature/009-fix-remover-grafico-pizza-adicionar-botao-voltar .worktrees/009-fix-analytics bia-desafio-agosto`
- [x] Entrar no worktree: `cd .worktrees/009-fix-analytics`
- [x] Confirmar branch correto: `git branch --show-current`

### 2. Alterações no Componente Analytics

**Arquivo:** `client/src/components/Analytics.jsx`

#### 2.1. Atualizar Imports
- [x] Remover `PieChart`, `Pie` e `Cell` das importações do recharts
- [x] Adicionar `useNavigate` do react-router-dom
- [x] Import final deve ser:
```javascript
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { useNavigate } from "react-router-dom";
```

#### 2.2. Adicionar Hook de Navegação
- [x] Dentro do componente `Analytics`, adicionar:
```javascript
const navigate = useNavigate();
```

#### 2.3. Remover Código do Gráfico de Pizza
- [x] Remover a constante `dataPie`
- [x] Remover a constante `COLORS`
- [x] Remover toda a seção `<div className="chart-wrapper">` do gráfico de pizza
- [x] Manter apenas o gráfico de barras

#### 2.4. Adicionar Botão Voltar
- [x] Adicionar botão no início do `<div className="analytics-header">`, **antes** do `<h2>`
- [x] Código do botão:
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

- [x] Adicionar ao final do arquivo:
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
- [x] Instalar dependências (se necessário): `npm install`
- [x] Build do frontend: `cd client && npm run build`
- [x] Verificar que o build foi concluído com sucesso
- [x] Confirmar redução no tamanho do bundle JS (deve diminuir ~19-20 KB)

#### 4.2. Teste com Docker Compose
- [x] Voltar ao diretório raiz do worktree
- [x] Build do Docker: `docker compose build`
- [x] Subir containers: `docker compose up -d`
- [x] Aguardar containers iniciarem

#### 4.3. Validações Funcionais
- [x] Acessar http://localhost:3001
- [x] Navegar para o Dashboard (clicar em "Dashboard" no header)
- [x] **Verificar:** Botão "← Voltar" está visível no topo da página
- [x] **Verificar:** Apenas gráfico de barras está sendo exibido
- [x] **Verificar:** Gráfico de pizza foi removido
- [x] **Testar:** Clicar no botão "← Voltar" e confirmar que retorna à home
- [x] **Testar:** Animação do botão ao passar o mouse (hover)
- [x] **Testar:** Funcionalidade em tema claro e escuro

#### 4.4. Validações Técnicas
- [x] Verificar console do navegador para erros
- [x] Confirmar que não há imports não utilizados
- [x] Verificar que o código está limpo (sem código comentado relacionado ao PieChart)

### 5. Commit e Push
- [x] Parar containers: `docker compose down`
- [x] Adicionar arquivos alterados: `git add client/src/components/Analytics.jsx client/src/index.css`
- [x] Commit: `git commit -m "fix: remover gráfico de pizza e adicionar botão voltar no dashboard"`
- [x] Push: `git push origin feature/009-fix-remover-grafico-pizza-adicionar-botao-voltar`

### 6. Informar Conclusão
- [x] Informar ao PO que a task está concluída e pronta para revisão
- [x] Mencionar que todos os testes foram executados com sucesso
- [x] Aguardar PO para criação do PR e finalização

## Critérios de Aceite
- [x] Gráfico de pizza completamente removido do código e da interface
- [x] Botão "← Voltar" visível e funcional no topo da página Analytics
- [x] Botão redireciona corretamente para a home (`/`)
- [x] Estilo do botão está consistente com o design da aplicação
- [x] Animações do botão funcionando corretamente
- [x] Sem erros no console do navegador
- [x] Build do frontend reduzido em tamanho (~19-20 KB)
- [x] Funcionalidade testada em tema claro e escuro

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

