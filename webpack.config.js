var webpack = require('webpack');
var path = require("path");

module.exports = {
  entry: {
    application: "./frontend/entry.jsx"
  },
  output: {
    path: path.join(__dirname, 'public', 'javascripts'),
    filename: "[name].js"
  },
  module: {
    loaders: [
      {
        test: /\.jsx$/,
        exclude: /node_modules/,
        loader: 'babel-loader'
      },
      {
        test: /\.woff$/,
        loader: "url-loader?prefix=font/&limit=5000"
      }
    ]
  },
  resolve: {
    extensions: ['', '.js', '.json', '.jsx'],
    root: path.resolve(__dirname, 'frontend')
  }
};
