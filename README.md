# vk-sync

Syncs music between vk.com and a local folder.

## Prerequisites

- `npm install`
- `bower install`
- `cd app/assets`, `npm install`, `cd ../..`

## Dev cycle

- `npm start` - this will watch for changes and recompile the code.
- `npm run app` - this will start your app. It'll reload on changes. Open devtools to avoid window requesting attention on reload.

## Deploy

- `npm run prod` - this will watch for changes and recompile minified code to `dist/cache/sources`.
- For now, assemble the app manually - merge an NW.js distribution `node_modules/nw/nwjs` with `dist/cache/sources`, launch using `nw.exe`.

## Licence - [MIT](LICENSE)
