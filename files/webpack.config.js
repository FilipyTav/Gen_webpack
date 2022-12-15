const path = require("path");

module.exports = {
    mode: "development",
    entry: {
        index: "./src/js/index.{{----SCRIPT----}}",
    },
    devtool: "inline-source-map",
    output: {
        filename: "main.js",
        path: path.resolve(__dirname, "dist"),
    },
    module: {
        rules: [
            {
                test: /\.css$/i,
                use: ["style-loader", "css-loader"],
            },
        ],
    },
};
