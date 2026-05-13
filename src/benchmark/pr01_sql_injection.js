/**
 * SAST-BENCHMARK — remediated SQL injection (parameterized query).
 * Safe to analyze; do not deploy or merge to production systems.
 */
const sqlite3 = require("sqlite3").verbose();

module.exports = function register(app) {
  const db = new sqlite3.Database(":memory:");
  db.serialize(() => {
    db.run("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    db.run("INSERT INTO users (name) VALUES ('alice'), ('bob')");
  });

  app.get("/benchmark/pr01/users", (req, res) => {
    const name = String(req.query.name ?? "");
    const sql = "SELECT * FROM users WHERE name = ?";
    db.all(sql, [name], (err, rows) => {
      if (err) return res.status(500).json({ error: String(err.message) });
      return res.json(rows);
    });
  });
};
