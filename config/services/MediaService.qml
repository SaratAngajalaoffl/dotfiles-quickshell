// Now-playing via MPRIS. Replaces waybar's custom/playback module and its
// current_playback.sh / should_show_playback.sh scripts.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    // Prefer a player that is actually playing, so a paused Spotify window
    // doesn't hide a playing browser tab.
    readonly property var player: {
        var players = Mpris.players.values
        if (players.length === 0)
            return null
        for (var i = 0; i < players.length; i++)
            if (players[i].isPlaying)
                return players[i]
        return players[0]
    }

    readonly property bool active: !!player && player.trackTitle !== ""

    readonly property string title:  player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album:  player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""

    readonly property bool playing: player ? player.isPlaying : false

    readonly property string glyph: playing ? "\uf04b" : "\uf04c"   // play / pause

    // Truncated "title · artist" for the bar.
    readonly property string label: {
        var t = title
        var a = artist
        if (t === "") return ""
        return a === "" ? t : t + "  ·  " + a
    }

    readonly property bool canToggle: player ? player.canTogglePlaying : false
    readonly property bool canNext:   player ? player.canGoNext       : false
    readonly property bool canPrev:   player ? player.canGoPrevious   : false

    function toggle() {
        if (player && player.canTogglePlaying)
            player.togglePlaying()
    }

    function next() {
        if (player && player.canGoNext)
            player.next()
    }

    function previous() {
        if (player && player.canGoPrevious)
            player.previous()
    }
}
