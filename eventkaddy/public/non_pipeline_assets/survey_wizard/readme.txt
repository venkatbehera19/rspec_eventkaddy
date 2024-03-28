How to Make Changes
===================

You must have node and npm installed (they are already installed on neptune. Then run npm install to install the dependencies listed in package.json.

Do not edit the index.min.js file directly. It is compiled when running webpack (or webpack --watch to listen for file changes as you work). It uses a javascript package called babel, which transpiles the common js code in these directories into ES5 Javascript, which should be supported virtually everywhere. The index.min.js file is then linked to directly in the relevant html page in the rails app.

On neptune, I have to use 'npm run build' (a command defined in package.json scripts) since webpack is not installed globally.

Hermes
======

Hermes ubuntu version is so out of date that node and npm can't be updated, and thus npm install fails. So I've just copied index.min.js manually.
