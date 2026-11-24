// Ponto de entrada do `npm start`.
// Com RUN_MIGRATIONS=true, aplica as migrations antes de subir o servidor.
// Útil quando o banco é privado (RDS) e ninguém de fora consegue rodar o db:migrate.

// dd-trace deve ser inicializado antes de qualquer outro require para instrumentar
// automaticamente Express, Sequelize/pg e http — sem mudar o resto do código.
require("dd-trace").init({
  logInjection: true, // injeta trace_id e span_id nos logs para correlação no Datadog
});

const { spawnSync } = require("child_process");

if (process.env.RUN_MIGRATIONS === "true") {
  console.log("[migrations] RUN_MIGRATIONS=true, aplicando migrations...");
  // No Windows o npx é npx.cmd e precisa de shell; no Linux/container, não.
  const win = process.platform === "win32";
  const r = spawnSync(win ? "npx.cmd" : "npx", ["sequelize", "db:migrate"], { stdio: "inherit", shell: win });
  if (r.status !== 0) {
    // Sai com erro: o container reinicia e o motivo fica no log, em vez de subir sem tabela.
    console.error("[migrations] falhou, servidor não vai subir.");
    process.exit(1);
  }
  console.log("[migrations] ok.");
}

require("./server");
