// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.SpotifyPlayer = {
    mounted() {
        console.log("mounted()")
    },
    updated() {
        console.log("Updated()")
        this.initializePlayer();
    },
    initializePlayer() {
      const playerElement = document.getElementById('spotify-player');
      const token = playerElement.getAttribute('data');
      const player = new Spotify.Player({
        name: 'Web Playback SDK Quick Start Player',
        getOAuthToken: cb => { cb(token); },
        volume: 0.5
      });

      player.addListener('ready', ({ device_id }) => {
        console.log('Ready with Device ID: ', device_id);
        this.pushEvent("set-device-id", {device_id: device_id})
      });

      // Add all your player event listeners here
      document.getElementById('togglePlay').onclick = function() {
        console.log("Toggle Play")
        player.togglePlay();
      };
      document.getElementById('playSDK').onclick = function() {
        player.togglePlay().then(() => {
          console.log('Toggled playback!');
        });
      };

      player.connect();
    },
  };


  window.onSpotifyWebPlaybackSDKReady = () => {
    // Actions to take once the SDK is ready, if any.

    //   //* Ready
    //   player.addListener('ready', ({ device_id }) => {
    //     console.log('Ready with Device ID', device_id);
    //     liveSocket.getSocket().pushEvent('set-device-id', {device_id: device_id});
    // });

    // //* Not Ready
    // player.addListener('not_ready', ({ device_id }) => {
    //     console.log('Device ID has gone offline', device_id);
    // });

    // player.addListener('initialization_error', ({ message }) => {
    //     console.error(message);
    // });

    // player.addListener('authentication_error', ({ message }) => {
    //     console.error(message);
    // });

    // player.addListener('account_error', ({ message }) => {
    //     console.error(message);
    // });

    // document.getElementById('togglePlay').onclick = function() {
    //   console.log("Toggle Play")
    //   player.togglePlay();
    // };
    // document.getElementById('playSDK').onclick = function() {
    //   player.togglePlay().then(() => {
    //     console.log('Toggled playback!');
    //   });
    // };
};


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

