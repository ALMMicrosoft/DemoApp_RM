/**
 * SAST-BENCHMARK — synthetic hardcoded credential for secret-scanning / CodeQL experiments.
 * Not a real key; replace with env vars in any real code.
 */
const BENCHMARK_SYNTHETIC_API_KEY = "benchmark-synthetic-api-key-DO-NOT-USE-IN-PROD-a1b2c3d4";

module.exports = function register(app) {
  app.get("/benchmark/pr03/config", (_req, res) => {
    return res.json({
      mode: "benchmark",
      apiKey: BENCHMARK_SYNTHETIC_API_KEY,
    });
  });
};
