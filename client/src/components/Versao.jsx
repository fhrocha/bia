import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";

const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8080";

const Versao = () => {
  // 'checking' | 'online' | 'offline'
  const [status, setStatus] = useState("checking");
  const [versaoTexto, setVersaoTexto] = useState("");

  const fetchVersao = async () => {
    setStatus("checking");

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);

      const response = await fetch(`${apiUrl}/api/versao`, {
        signal: controller.signal,
        cache: "no-cache",
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const texto = await response.text(); // ex: "Bia 4.3.0"
      setVersaoTexto(texto);
      setStatus("online");
    } catch {
      setStatus("offline");
    }
  };

  useEffect(() => {
    fetchVersao();
  }, []);

  // Separa "Bia" de "4.3.0"
  const [nomeApp, numeroVersao] = versaoTexto ? versaoTexto.split(" ") : ["—", "—"];

  return (
    <div className="tasks-container">
      {/* Loading */}
      {status === "checking" && (
        <div className="task">
          <div className="task-content">
            <h3>🟡 Verificando...</h3>
            <p className="task-date">Aguarde um momento</p>
          </div>
        </div>
      )}

      {/* Erro */}
      {status === "offline" && (
        <div className="task reminder">
          <div className="task-content">
            <h3>🔴 Indisponível</h3>
            <p className="task-date">Não foi possível carregar as informações.</p>
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
