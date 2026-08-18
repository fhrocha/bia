import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";

const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8080";

const Versao = () => {
  // 'checking' | 'online' | 'offline'
  const [status, setStatus] = useState("checking");
  const [versaoTexto, setVersaoTexto] = useState("");
  const [erro, setErro] = useState(null);

  const fetchVersao = async () => {
    setStatus("checking");
    setErro(null);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);

      const response = await fetch(`${apiUrl}/api/versao`, {
        signal: controller.signal,
        cache: "no-cache",
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const texto = await response.text(); // ex: "Bia 4.3.0"
      setVersaoTexto(texto);
      setStatus("online");
    } catch (error) {
      setStatus("offline");
      setErro(error.message || "Não foi possível conectar à API.");
    }
  };

  useEffect(() => {
    fetchVersao();
  }, []);

  // Separa "Bia" de "4.3.0"
  const [nomeApp, numeroVersao] = versaoTexto ? versaoTexto.split(" ") : ["—", "—"];

  const statusIcone = {
    checking: "🟡",
    online: "🟢",
    offline: "🔴",
  }[status];

  const statusLabel = {
    checking: "Verificando...",
    online: "Online",
    offline: "Offline",
  }[status];

  return (
    <div className="tasks-container">
      {/* Loading */}
      {status === "checking" && (
        <div className="task">
          <div className="task-content">
            <h3>🟡 Verificando API...</h3>
            <p className="task-date">Aguarde um momento</p>
          </div>
        </div>
      )}

      {/* Erro */}
      {status === "offline" && (
        <div className="task reminder">
          <div className="task-content">
            <h3>🔴 API indisponível</h3>
            <p className="task-date">{erro}</p>
          </div>
          <div className="task-actions">
            <button
              className="task-priority"
              onClick={fetchVersao}
              title="Tentar novamente"
            >
              🔄
            </button>
          </div>
        </div>
      )}

      {/* Dados carregados */}
      {status === "online" && (
        <>
          {/* Nome da aplicação */}
          <div className="task">
            <div className="task-content">
              <h3>Nome da aplicação</h3>
              <p className="task-date">{nomeApp}</p>
            </div>
          </div>

          {/* Versão */}
          <div className="task">
            <div className="task-content">
              <h3>Versão</h3>
              <p className="task-date">{numeroVersao}</p>
            </div>
          </div>

          {/* Status */}
          <div className="task">
            <div className="task-content">
              <h3>Status da API</h3>
              <p className="task-date">
                {statusIcone} {statusLabel}
              </p>
            </div>
          </div>

          {/* URL da API */}
          <div className="task">
            <div className="task-content">
              <h3>URL da API</h3>
              <p className="task-date">{apiUrl}</p>
            </div>
          </div>
        </>
      )}

      {/* Rodapé com link de volta */}
      <div style={{ padding: "1rem 1.5rem", borderTop: "1px solid var(--border-color)" }}>
        <Link to="/" className="back-button">
          ← Voltar
        </Link>
      </div>
    </div>
  );
};

export default Versao;
