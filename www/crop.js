/* global cordova */
var crop = module.exports = function cropImage (success, fail, image, options) {
  options = options || {}
  options.quality = options.quality || 100
  options.targetWidth = options.targetWidth || -1
  options.targetHeight = options.targetHeight || -1
  options.allowRotate = options.allowRotate || false
  options.keepCropAspectRatio = !!options.keepCropAspectRatio
  options.showCropGrid = !!options.showCropGrid
  options.toolbarTitle = options.toolbarTitle || ""
  options.toolbarColor = options.toolbarColor || "#FFFFFF"
  options.statusBarColor  = options.statusBarColor || "#F5F5F5"
  options.toolbarWidgetColor = options.toolbarWidgetColor || "#000000"
  options.rootViewBackgroundColor = options.rootViewBackgroundColor || "#20242F"
  options.activeControlsWidgetColor = options.activeControlsWidgetColor || "#FF6300"
  return cordova.exec(success, fail, 'CropPlugin', 'cropImage', [image, options])
}

module.exports.promise = function cropAsync (image, options) {
  return new Promise(function (resolve, reject) {
    crop(resolve, reject, image, options)
  })
}
