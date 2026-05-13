/**
 * SAST-BENCHMARK — serves a static page with intentional DOM XSS pattern (innerHTML / location).
 */
const path = require("path");
const express = require("express");

module.exports = function register(app) {
  const root = path.join(__dirname, "..", "..", "public", "benchmark-pr05");
  app.use("/benchmark/pr05", express.static(root));
};
