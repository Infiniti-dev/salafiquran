process.env.NODE_ENV = process.env.NODE_ENV || "production";

const environment = require("./environment");

/*
const CompressionPlugin = require("compression-webpack-plugin");

environment.plugins.append(
  "Compression",
  new CompressionPlugin({
    filename: "[path].gz[query]",
    algorithm: "gzip", // gzip , zopfli
    cache: true,
    test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/
  })
);

// TODO: https://github.com/rails/webpacker/blob/master/docs/deployment.md#installing-the-ngx_brotli-module
environment.plugins.append(
  "Compression Brotli",
  new CompressionPlugin({
    filename: "[path].br[query]",
    algorithm: "brotliCompress",
    cache: true,
    test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/,
    compressionOptions: { level: 11 },
    threshold: 10240, // min file size in bytes to trigger the compression.
    minRatio: 0.8
  })
);
*/

const glob = require("glob-all");
const fs = require("fs");
const path = require("path");

// Configure PurgeCSS
const PurgecssPlugin = require("purgecss-webpack-plugin");

/*var whitelist_path = "config/webpack/purgecss/whitelist.json";
var whitelist = {};

if (fs.existsSync(whitelist_path)) {
  whitelist = JSON.parse(fs.readFileSync(whitelist_path));
}*/

environment.plugins.append(
  "PurgecssPlugin",
  new PurgecssPlugin({
    safelist: {
      standard: ["tajweed", ".h", "inline-comment", ".urdu", "sup", "select2"],
      deep: [/hlt/, 'aria-disabled', 'modal-open', /icon-/, /mushaf/],
      greedy: []
    },
    paths: glob.sync([
      path.join(__dirname, "../../app/javascript/**/*"),
      path.join(__dirname, "../../app/views/**/*")
    ], { nodir: true })
  })
);

module.exports = environment.toWebpackConfig();
