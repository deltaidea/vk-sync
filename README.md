# vk-sync

Syncs music between vk.com and a local folder.

![vk-sync](http://i.imgur.com/ZY111Ty.png)

## Prerequisites

- `npm install`
- `bower install`
- `cd app/assets`, `npm install`, `cd ../..`

## Dev cycle

- `npm start` - this will watch for changes and recompile the code.
- `npm run app` - this will start your app. It'll reload on changes. Open devtools to avoid window requesting attention on reload.

## Deploy

- `npm run prod` - this will watch for changes and recompile minified code to `dist/cache`.
- `npm run dist` - this will compile distrs (portable and installer) to `dist/releases`. Requires WinRAR.

## Licence - [MIT](LICENSE)
