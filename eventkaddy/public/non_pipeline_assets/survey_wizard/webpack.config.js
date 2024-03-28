// var debug   = process.env.NODE_ENV !== "production";
var debug = true;
var webpack = require('webpack');

module.exports = {
    context: __dirname,
    devtool: debug ? "inline-sourcemap" : false,
    entry:   "./index.js",
    mode: 'development',
    module: {
        rules: [
            {
                test: /\.js$/,
                // for some reason, including lib in the exclude broke this.
                // Probably because babel-loader or something has a directory with the same name.
                exclude: /(node_modules|bower_components)/,
                use: {
                    loader: "babel-loader",
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            }
        ]
    },
    output:  {
        path: __dirname,
        filename: "index.min.js"
    },
    plugins: debug ? [] : [
        // new webpack.optimize.DedupePlugin(),
        // new webpack.optimize.OccurenceOrderPlugin(),
        // new webpack.optimize.UglifyJsPlugin({ mangle: false, sourcemap: false }),
    ],
};
