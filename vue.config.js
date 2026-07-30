const path = require('path')

module.exports = {
  publicPath: './',
  outputDir: 'dist',
  productionSourceMap: false,
  devServer: {
    port: 8080,
    open: false,
    host: '0.0.0.0',
    allowedHosts: 'all'
  },
  configureWebpack: {
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src')
      }
    }
  },
  css: {
    loaderOptions: {
      postcss: {
        postcssOptions: {
          plugins: [
            require('postcss-px-to-viewport-8-plugin')({
              unitToConvert: 'px',
              viewportWidth: 375,
              unitPrecision: 5,
              propList: ['*'],
              viewportUnit: 'vw',
              fontViewportUnit: 'vw',
              selectorBlackList: ['.ignore-vw', '.el-message', '.el-message-box'],
              minPixelValue: 1,
              mediaQuery: false,
              replace: true,
              exclude: [/node_modules\/(element-ui|vant)/]
            })
          ]
        }
      }
    }
  }
}