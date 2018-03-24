/**
 * Captures the full height document even if it's not showing on the screen or captures with the provided range of screen sizes.
 * usage : phantomjs responsive-screenshot.js {url} [output format] [doClipping]
*/

phantom.onError = function(msg, trace) {
  var msgStack = ['PHANTOM ERROR: ' + msg];
  if (trace && trace.length) {
    msgStack.push('TRACE:');
    trace.forEach(function(t) {
      msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function +')' : ''));
    });
  }
  console.log(msgStack.join('\n'));
  phantom.exit(1);
};

var args = require('system').args;
var fs = require('fs');
var page = new WebPage();

if ( 2 === args.length ) {
    console.log('Url address and storage folder is required');
    phantom.exit();
}

var urlAddress = args[1].toLowerCase();
var output = args[2];

function ISODateString(d) {
    function pad(n) {return n<10 ? '0'+n : n}
    return d.getUTCFullYear()+'-'
         + pad(d.getUTCMonth()+1)+'-'
         + pad(d.getUTCDate())+'T'
         + pad(d.getUTCHours())+':'
         + pad(d.getUTCMinutes())+':'
         + pad(d.getUTCSeconds())+'Z'
}

page.onLoadFinished = function (status) {
    if ( 'success' !== status ) {
        console.log('[ERROR] Page load finished, but failed.');
    } else {
        page.render(output);
    }
    fin = Date.now();
    finDate = new Date();
    msec = fin - t;
    console.log('[INFO] Load finished ' + finDate.toISOString());
    console.log('[INFO] Load took ' + msec + ' msec');
    phantom.exit();
};

page.onUrlChanged = function(targetUrl) {
    if ( "about:blank" != targetUrl ) {
        console.log('[INFO] URL changed to: ' + targetUrl);
    }
};

page.onResourceTimeout = function(request) {
    console.log('[WARNING] Resource #' 
                 + request.id 
                 + ' timed out: ' 
                 + JSON.stringify(request));
};

page.onResourceError = function(resourceError) {
    console.log('[WARNING] Resource #'
                + resourceError.id
                + ' failed to load: '
                + JSON.stringify(resourceError));
};


page.onPrompt = function(msg, defaultVal) {
    console.log("[INFO] Prompt: '"
                 + msg
                 + "', default value: '"
                 + defaultVal
                 + "'");
    return "Nomen nescio " + Date.now();
};

page.settings.userAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.162 Safari/537.36';

page.settings.resourceTimeout = 10000000; // 10000;

// https://www.w3schools.com/browsers/browsers_display.asp
shotSize = { width: 1366, height: 768 };

page.viewportSize = shotSize;
page.clipRect = shotSize;

var t = Date.now(); // ms since 1970
var tDate = new Date(); // date object
console.log('[INFO] Starting load at ' + tDate.toISOString());

page.open(urlAddress);
