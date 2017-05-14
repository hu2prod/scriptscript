/*
This script allows debugging the application in Chrome Dev Tools. Run it with

node --inspect inspect-proxy.js args

Then open about:inspect in your Chrome
(also should work in any webkit-based browser but doesn't work in Firefox).
Then click the Open dedicated DevTools for Node link.
You’ll get a popup window for debugging your node session.

Based on this recipe:
https://medium.com/@paul_irish/debugging-node-js-nightlies-with-chrome-devtools-7c4a1b95ae27
*/

require('iced-coffee-script').register();
require('./run.coffee');