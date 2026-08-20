import React from "react";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { useNavigate } from "react-router-dom";
import { useTheme } from "../contexts/ThemeContext.jsx";

const Analytics = ({ tasks }) => {
  const { isDarkMode } = useTheme();
  const navigate = useNavigate();

  // Processar dados para o gráfico
  const importantes = tasks.filter(t => t.importante).length;
  const naoImportantes = tasks.filter(t => !t.importante).length;
  
  const dataBar = [
    { name: "Importante", quantidade: importantes },
    { name: "Não Importante", quantidade: naoImportantes }
  ];

  // Cores para o tema
  const colors = isDarkMode 
    ? {
        importante: "#34d399",
        naoImportante: "#60a5fa",
        text: "#f9fafb",
        grid: "#374151",
        background: "#1f2937"
      }
    : {
        importante: "#10b981",
        naoImportante: "#3b82f6",
        text: "#1f2937",
        grid: "#e5e7eb",
        background: "#ffffff"
      };

  return (
    <div className="analytics-container">
      <div className="analytics-header">
        <button 
          onClick={() => navigate('/')} 
          className="btn-back"
          title="Voltar para tela principal"
        >
          ← Voltar
        </button>
        <h2>📊 Dashboard de Tarefas</h2>
        <p className="analytics-subtitle">Visualização da distribuição de tarefas por prioridade</p>
      </div>

      {/* Cards de Estatísticas */}
      <div className="stats-summary">
        <div className="stat-card stat-total">
          <div className="stat-icon">📝</div>
          <div className="stat-content">
            <h3>Total de Tarefas</h3>
            <p className="stat-value">{tasks.length}</p>
          </div>
        </div>
        <div className="stat-card stat-importante">
          <div className="stat-icon">⭐</div>
          <div className="stat-content">
            <h3>Importantes</h3>
            <p className="stat-value">{importantes}</p>
            <p className="stat-percentage">
              {tasks.length > 0 ? `${Math.round((importantes / tasks.length) * 100)}%` : '0%'}
            </p>
          </div>
        </div>
        <div className="stat-card stat-normal">
          <div className="stat-icon">📌</div>
          <div className="stat-content">
            <h3>Não Importantes</h3>
            <p className="stat-value">{naoImportantes}</p>
            <p className="stat-percentage">
              {tasks.length > 0 ? `${Math.round((naoImportantes / tasks.length) * 100)}%` : '0%'}
            </p>
          </div>
        </div>
      </div>

      {tasks.length > 0 ? (
        <>
          {/* Gráfico de Barras */}
          <div className="chart-wrapper">
            <h3 className="chart-title">Gráfico de Barras</h3>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={dataBar} margin={{ top: 20, right: 30, left: 0, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke={colors.grid} />
                <XAxis 
                  dataKey="name" 
                  stroke={colors.text}
                  style={{ fontSize: '0.875rem' }}
                />
                <YAxis 
                  stroke={colors.text}
                  style={{ fontSize: '0.875rem' }}
                />
                <Tooltip 
                  contentStyle={{
                    backgroundColor: colors.background,
                    border: `1px solid ${colors.grid}`,
                    borderRadius: '6px',
                    color: colors.text
                  }}
                />
                <Legend 
                  wrapperStyle={{
                    paddingTop: '10px',
                    fontSize: '0.875rem'
                  }}
                />
                <Bar 
                  dataKey="quantidade" 
                  fill={colors.importante}
                  radius={[8, 8, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </>
      ) : (
        <div className="empty-analytics">
          <h3>📭 Nenhuma tarefa cadastrada</h3>
          <p>Adicione tarefas para visualizar os gráficos e estatísticas.</p>
        </div>
      )}
    </div>
  );
};

export default Analytics;
