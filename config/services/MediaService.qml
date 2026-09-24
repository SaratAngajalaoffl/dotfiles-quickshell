// Now-playing for the island: Spotify (via SpotifyService / `soloist ctl`,
// which has no MPRIS) merged with any MPRIS player (browser tabs, etc.).
// Replaces waybar's custom/playback module and its current_playback.sh /
// should_show_playback.sh scripts.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    // Prefer an MPRIS player that is actually playing, so a paused browser
    // tab doesn't hide a playing one.
    readonly property var player: {
        var players = Mpris.players.values
        if (players.length === 0)
            return null
        for (var i = 0; i < players.length; i++)
            if (players[i].isPlaying)
                return players[i]
        return players[0]
    }

    readonly property bool _spotifyHasTrack: SpotifyService.running && SpotifyService.title !== ""

    // Spotify wins while it plays, or while it's paused and no MPRIS player
    // is playing.
    readonly property bool useSpotify: _spotifyHasTrack
        && (SpotifyService.playing || !(player && player.isPlaying))

    readonly property bool active: useSpotify || (!!player && player.trackTitle !== "")

    readonly property string title:  useSpotify ? SpotifyService.title
                                   : player ? (player.trackTitle || "") : ""
    readonly property string artist: useSpotify ? SpotifyService.artist
                                   : player ? (player.trackArtist || "") : ""
    readonly property string album:  useSpotify ? ""
                                   : player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: useSpotify ? SpotifyService.artUrl
                                   : player ? (player.trackArtUrl || "") : ""

    readonly property bool playing: useSpotify ? SpotifyService.playing
                                  : player ? player.isPlaying : false

    readonly property string glyph: playing ? "" : ""   // play / pause

    // Truncated "title · artist" for the bar.
    readonly property string label: {
        var t = title
        var a = artist
        if (t === "") return ""
        return a === "" ? t : t + "  ·  " + a
    }

    readonly property bool canToggle: useSpotify || (player ? player.canTogglePlaying : false)
    readonly property bool canNext:   useSpotify || (player ? player.canGoNext       : false)
    readonly property bool canPrev:   useSpotify || (player ? player.canGoPrevious   : false)

    function toggle() {
        if (useSpotify) SpotifyService.toggle()
        else if (player && player.canTogglePlaying)
            player.togglePlaying()
    }

    function next() {
        if (useSpotify) SpotifyService.next()
        else if (player && player.canGoNext)
            player.next()
    }

    function previous() {
        if (useSpotify) SpotifyService.previous()
        else if (player && player.canGoPrevious)
            player.previous()
    }
}
