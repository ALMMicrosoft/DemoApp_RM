/**
 * SAST-BENCHMARK — intentional reflected XSS (unescaped user input in HTML). For SAST evaluation only.
 */
module.exports = function register(app) {
  app.get("/benchmark/pr04/search", (req, res) => {
    const q = String(req.query.q ?? "");
    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.send(
      "<!doctype html><html><head><title>benchmark</title></head><body><p>Results for: " +
        q +
        "</p></body></html>",
    );
  });
};
