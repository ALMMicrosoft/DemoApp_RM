/**
 * SAST-BENCHMARK — intentional SQL injection (template interpolation). Detection-rate experiment only.
 */
const sqlite3 = require("sqlite3").verbose();

module.exports = function register(app) {
  const db = new sqlite3.Database(":memory:");
  db.serialize(() => {
    db.run("CREATE TABLE items (id INTEGER PRIMARY KEY, qty INTEGER)");
    db.run("INSERT INTO items (qty) VALUES (10), (20)");
  });

  app.get("/benchmark/pr02/items", (req, res) => {
    const id = String(req.query.id ?? "1");
    const sql = `SELECT * FROM items WHERE id = ${id}`;
    db.all(sql, (err, rows) => {
      if (err) return res.status(500).json({ error: String(err.message) });
      return res.json(rows);
    });
  });
};
