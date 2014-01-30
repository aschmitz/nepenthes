var page = require('webpage').create(),
    system = require('system'),
    address, output, size;

if (system.args.length != 2) {
  console.log('Usage: get_screenshot.js URL');
  phantom.exit(1);
} else {
  address = system.args[1];
  page.viewportSize = { width: 800, height: 600 };
  
  // Squelch these so they don't interefere with our image output.
  page.onError = function (msg) {};
  
  page.open(address, function (status) {
    if (status !== 'success') {
      console.log('failed');
      phantom.exit();
    }
    
    page.evaluate(function() {
      if (document.body.bgColor == '' &&
          document.body.style.backgroundColor == '') {
        document.body.bgColor = 'white';
      }
    });
    
    window.setTimeout(function () {
      console.log(page.url);
      console.log(page.renderBase64('PNG'));
      phantom.exit();
    }, 2000);
  });
}
