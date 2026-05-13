/**
 * Baseline app — no deliberate vulns on main.
 * Benchmark PRs add files under src/benchmark/.
 */
const express = require("express");
const path = require("path");

const app = express();
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

// Load optional benchmark routes if present (each PR adds one module).
const benchmarkDir = path.join(__dirname, "benchmark");
try {
  // eslint-disable-next-line import/no-dynamic-require, global-require
  require("fs")
    .readdirSync(benchmarkDir)
    .filter((f) => f.endsWith(".js"))
    .forEach((f) => {
      // eslint-disable-next-line import/no-dynamic-require, global-require
      require(path.join(benchmarkDir, f))(app);
    });
} catch {
  // no benchmark folder yet
}

const port = process.env.PORT || 3000;
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`listening on ${port}`);
});
